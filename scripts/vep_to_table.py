#!/usr/bin/env python3
"""Flatten a VEP-annotated VCF into an analysis-ready TSV.

One output row per (variant, ALT allele, VEP consequence/transcript).
The VEP ``CSQ`` INFO field is split into columns using the ``Format:``
description in the VCF header, and the sample's FORMAT fields (GT, DP, GQ, AD)
are added. Uses only the Python standard library.

Example:
    python scripts/vep_to_table.py --vcf results/annotation/HG001.vep.vcf.gz \
        --sample HG001 --out results/tables/HG001.variants.tsv
"""
from __future__ import annotations

import argparse
import csv
import gzip
import re
import sys
from collections import Counter
from pathlib import Path

# CSQ sub-fields exported to the table (missing ones are left empty)
CSQ_KEEP = [
    "Consequence", "IMPACT", "SYMBOL", "Gene", "Feature_type", "Feature",
    "BIOTYPE", "EXON", "INTRON", "HGVSc", "HGVSp", "VARIANT_CLASS", "PICK",
]
BASE_COLS = [
    "sample_id", "chrom", "pos", "ref", "alt", "qual", "filter",
    "gt", "dp", "gq", "ad_ref", "ad_alt",
]


def open_text(path: str):
    return gzip.open(path, "rt") if path.endswith((".gz", ".bgz")) else open(path)


def clean(value: str | None) -> str:
    return "" if value in (None, ".") else value


def parse_info(info: str) -> dict[str, str]:
    out = {}
    for item in info.split(";"):
        key, _, val = item.partition("=")
        out[key] = val
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--vcf", required=True, help="VEP-annotated VCF (.vcf or .vcf.gz)")
    ap.add_argument("--out", required=True, help="Output TSV path")
    ap.add_argument("--sample", help="Sample column to report (default: first sample)")
    args = ap.parse_args()

    csq_fields: list[str] | None = None
    sample_idx: int | None = None
    sample_name = args.sample
    n_records = 0
    n_rows = 0
    impacts: Counter[str] = Counter()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open_text(args.vcf) as vcf, open(args.out, "w", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(BASE_COLS + [c.lower() for c in CSQ_KEEP])

        for line in vcf:
            if line.startswith("##INFO=<ID=CSQ"):
                match = re.search(r'Format: ([^"]+)"', line)
                if not match:
                    sys.exit("ERROR: could not parse CSQ Format from VCF header")
                csq_fields = match.group(1).split("|")
                continue
            if line.startswith("##"):
                continue
            if line.startswith("#CHROM"):
                header = line.rstrip("\n").split("\t")
                samples = header[9:]
                if not samples:
                    sys.exit("ERROR: VCF has no sample columns")
                if sample_name and sample_name in samples:
                    sample_idx = header.index(sample_name)
                else:
                    sample_idx, sample_name = 9, samples[0]
                if csq_fields is None:
                    sys.exit("ERROR: no CSQ header found - is this a VEP-annotated VCF?")
                continue

            cols = line.rstrip("\n").split("\t")
            chrom, pos, _id, ref, alt, qual, filt, info = cols[:8]
            fmt = dict(zip(cols[8].split(":"), cols[sample_idx].split(":")))
            alts = alt.split(",")
            ad = fmt.get("AD", ".").split(",")
            n_records += 1

            csq_raw = parse_info(info).get("CSQ", "")
            entries = [e.split("|") for e in csq_raw.split(",")] if csq_raw else [[]]

            for entry in entries:
                csq = dict(zip(csq_fields, entry))
                # ALLELE_NUM (VEP --allele_number) links each CSQ to its ALT allele
                allele_num = int(csq.get("ALLELE_NUM") or 1)
                alt_allele = alts[allele_num - 1] if allele_num <= len(alts) else alt
                ad_alt = ad[allele_num] if len(ad) > allele_num else ""
                row = [
                    sample_name, chrom, pos, ref, alt_allele, clean(qual), clean(filt),
                    clean(fmt.get("GT")), clean(fmt.get("DP")), clean(fmt.get("GQ")),
                    clean(ad[0]), clean(ad_alt),
                ] + [clean(csq.get(c)) for c in CSQ_KEEP]
                writer.writerow(row)
                n_rows += 1
                impacts[csq.get("IMPACT") or "NA"] += 1

    print(f"{n_records} VCF records -> {n_rows} table rows ({args.out})", file=sys.stderr)
    print("rows by IMPACT: " + ", ".join(f"{k}={v}" for k, v in sorted(impacts.items())),
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
