# Germline variant calling with GATK HaplotypeCaller (restricted to the demo region)


def hard_filter_args():
    return " ".join(
        f"--filter-name {f['name']} --filter-expression \"{f['expression']}\""
        for f in config["gatk"]["hard_filters"]
    )


rule haplotype_caller:
    input:
        bam=f"{OUT}/align/{{sample}}.dedup.bam",
        bai=f"{OUT}/align/{{sample}}.dedup.bam.bai",
        ref=REF,
        fai=f"{REF}.fai",
        dict=REF_DICT,
    output:
        vcf=f"{OUT}/variants/{{sample}}.raw.vcf.gz",
        tbi=f"{OUT}/variants/{{sample}}.raw.vcf.gz.tbi",
    params:
        java=config["gatk"]["java_opts"],
        region=REGION,
        extra=config["gatk"]["haplotypecaller_extra"],
    log:
        f"{LOGS}/haplotypecaller/{{sample}}.log",
    threads: 2
    shell:
        "gatk --java-options '{params.java}' HaplotypeCaller "
        "-R {input.ref} -I {input.bam} -L {params.region} -O {output.vcf} "
        "--native-pair-hmm-threads {threads} {params.extra} > {log} 2>&1"


rule hard_filter:
    input:
        vcf=f"{OUT}/variants/{{sample}}.raw.vcf.gz",
        tbi=f"{OUT}/variants/{{sample}}.raw.vcf.gz.tbi",
        ref=REF,
        dict=REF_DICT,
    output:
        vcf=f"{OUT}/variants/{{sample}}.filtered.vcf.gz",
        tbi=f"{OUT}/variants/{{sample}}.filtered.vcf.gz.tbi",
    params:
        java=config["gatk"]["java_opts"],
        filters=hard_filter_args(),
    log:
        f"{LOGS}/hard_filter/{{sample}}.log",
    shell:
        "gatk --java-options '{params.java}' VariantFiltration "
        "-R {input.ref} -V {input.vcf} -O {output.vcf} {params.filters} > {log} 2>&1"


rule bcftools_stats:
    input:
        f"{OUT}/variants/{{sample}}.filtered.vcf.gz",
    output:
        f"{OUT}/variants/{{sample}}.bcftools_stats.txt",
    log:
        f"{LOGS}/bcftools_stats/{{sample}}.log",
    shell:
        "bcftools stats {input} > {output} 2> {log}"
