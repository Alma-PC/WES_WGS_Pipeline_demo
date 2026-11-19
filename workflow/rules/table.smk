# Flatten the VEP-annotated VCF into an analysis-ready TSV


rule vep_to_table:
    input:
        f"{OUT}/annotation/{{sample}}.vep.vcf.gz",
    output:
        f"{OUT}/tables/{{sample}}.variants.tsv",
    log:
        f"{LOGS}/table/{{sample}}.log",
    shell:
        "python scripts/vep_to_table.py --vcf {input} --sample {wildcards.sample} "
        "--out {output} 2> {log}"
