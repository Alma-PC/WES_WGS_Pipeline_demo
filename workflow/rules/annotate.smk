# Functional annotation with Ensembl VEP.
# Runs offline against the Ensembl GFF3 + FASTA of chr20, so no VEP cache
# (20+ GB) is required. See https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html#gff


rule vep:
    input:
        vcf=f"{OUT}/variants/{{sample}}.filtered.vcf.gz",
        gff=GFF,
        gff_tbi=f"{GFF}.tbi",
        ref=REF,
        fai=f"{REF}.fai",
    output:
        vcf=f"{OUT}/annotation/{{sample}}.vep.vcf.gz",
        stats=f"{OUT}/annotation/{{sample}}.vep_summary.html",
    params:
        extra=config["vep"]["extra"],
    log:
        f"{LOGS}/vep/{{sample}}.log",
    conda:
        "../envs/vep.yml"
    threads: 2
    shell:
        "vep --input_file {input.vcf} --format vcf "
        "--output_file {output.vcf} --vcf --compress_output bgzip "
        "--gff {input.gff} --fasta {input.ref} "
        "--fork {threads} --stats_file {output.stats} --force_overwrite "
        "{params.extra} > {log} 2>&1"
