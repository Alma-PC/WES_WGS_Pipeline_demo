# Data sources and licences

All input data are public and are downloaded by [`scripts/download_data.sh`](../scripts/download_data.sh).
None of it is committed to this repository. The script writes a provenance record with
URLs, parameters and md5 checksums to `data/MANIFEST.txt`.

## 1. Sequencing reads: GIAB HG001 / NA12878

| Field | Value |
|---|---|
| Sample | HG001 (NA12878, Coriell cell line GM12878), the Genome in a Bottle reference sample |
| Provider | NIST Genome in a Bottle Consortium |
| Platform | Illumina HiSeq 2500, 2×148 bp, TruSeq PCR-free, ~300× total |
| Source file | `HG001.GRCh38_full_plus_hs38d1_analysis_set_minus_alts.300x.bam` (NHGRI novoalign alignment) |
| URL | <https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/NA12878/NIST_NA12878_HG001_HiSeq_300x/NHGRI_Illumina300X_novoalign_bams/> |
| Subset used | `chr20:33,000,000-33,500,000` (GRCh38), 10% of reads (≈30×), seed 42, properly paired reads only |
| Licence | GIAB data are produced by NIST, a U.S. Government agency, and are in the **public domain** in the United States. See the [NIST data policy](https://www.nist.gov/open/license) and the [GIAB data use statement](https://www.nist.gov/programs-projects/genome-bottle). |

**How the subset is produced:** `samtools view` reads only the requested region over HTTPS
through the BAM index, and subsampling hashes read names so both mates are kept together.
`samtools collate` and `samtools fastq` then turn the alignments back into paired FASTQ files.
The pipeline realigns these reads from scratch, so the original alignment is used only to
select reads.

**Caveat:** reads whose mate maps outside the window are discarded, so coverage drops
slightly at the window edges. This is expected and fine for a demo.

## 2. Reference genome: Ensembl GRCh38 chromosome 20

| Field | Value |
|---|---|
| File | `Homo_sapiens.GRCh38.dna.chromosome.20.fa.gz` |
| Release | Ensembl 116 |
| URL | <https://ftp.ensembl.org/pub/release-116/fasta/homo_sapiens/dna/> |
| Contig name | `20` (Ensembl style, no `chr` prefix) |
| Licence | Ensembl data are available without restriction. See the [Ensembl disclaimer and licence](https://www.ensembl.org/info/about/legal/disclaimer.html). |

Only chromosome 20 is used, which keeps the BWA-MEM2 index small (~2 GB RAM) while
keeping real GRCh38 coordinates.

## 3. Gene annotation: Ensembl GFF3 for chromosome 20

| Field | Value |
|---|---|
| File | `Homo_sapiens.GRCh38.116.chromosome.20.gff3.gz` |
| URL | <https://ftp.ensembl.org/pub/release-116/gff3/homo_sapiens/> |
| Use | Passed to Ensembl VEP with `--gff`, so no 20+ GB VEP cache is needed |
| Licence | Same as above (Ensembl, unrestricted) |

## 4. Sample metadata

`metadata/example_sample_metadata.tsv` is **synthetic**. Every value is invented to demonstrate
format harmonization, and it does not describe the real HG001 sample. Rows `DEMO-002` and
`demo_003` are fictitious.

## Citation

If you reuse these data, cite the original providers:

- Zook JM *et al.* (2016). Extensive sequencing of seven human genomes to characterize benchmark
  reference materials. *Scientific Data* 3, 160025. <https://doi.org/10.1038/sdata.2016.25>
- Ensembl: <https://www.ensembl.org/info/about/publications.html>
- McLaren W *et al.* (2016). The Ensembl Variant Effect Predictor. *Genome Biology* 17, 122.
  <https://doi.org/10.1186/s13059-016-0974-4>
