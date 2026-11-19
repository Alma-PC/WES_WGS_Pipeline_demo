# Duplicate marking with GATK (Picard) MarkDuplicates


rule mark_duplicates:
    input:
        f"{OUT}/align/{{sample}}.sorted.bam",
    output:
        bam=f"{OUT}/align/{{sample}}.dedup.bam",
        metrics=f"{OUT}/qc/markdup/{{sample}}.metrics.txt",
    params:
        java=config["gatk"]["java_opts"],
    log:
        f"{LOGS}/markdup/{{sample}}.log",
    shell:
        "gatk --java-options '{params.java}' MarkDuplicates "
        "-I {input} -O {output.bam} -M {output.metrics} "
        "--VALIDATION_STRINGENCY SILENT > {log} 2>&1"
