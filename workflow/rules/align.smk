# Alignment with BWA-MEM2, coordinate sorting, indexing and alignment stats


rule bwa_mem2_align:
    input:
        r1=f"{OUT}/trimmed/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/trimmed/{{sample}}_R2.fastq.gz",
        ref=REF,
        idx=rules.bwa_mem2_index.output,
    output:
        bam=temp(f"{OUT}/align/{{sample}}.sorted.bam"),
    params:
        # Read group is required by GATK
        rg=lambda wc: f"@RG\\tID:{wc.sample}\\tSM:{wc.sample}\\tPL:ILLUMINA\\tLB:{wc.sample}_lib1",
        sort_mem=config["samtools"]["sort_mem_per_thread"],
    log:
        f"{LOGS}/align/{{sample}}.log",
    threads: THREADS
    shell:
        "(bwa-mem2 mem -t {threads} -R '{params.rg}' {input.ref} {input.r1} {input.r2} "
        "| samtools sort -@ {threads} -m {params.sort_mem} -o {output.bam} -) 2> {log}"


rule samtools_index:
    input:
        "{prefix}.bam",
    output:
        "{prefix}.bam.bai",
    log:
        f"{LOGS}/index/{{prefix}}.log",
    shell:
        "samtools index {input} 2> {log}"


rule samtools_stats:
    input:
        bam=f"{OUT}/align/{{sample}}.dedup.bam",
        bai=f"{OUT}/align/{{sample}}.dedup.bam.bai",
    output:
        stats=f"{OUT}/qc/samtools/{{sample}}.stats.txt",
        flagstat=f"{OUT}/qc/samtools/{{sample}}.flagstat.txt",
    log:
        f"{LOGS}/samtools_stats/{{sample}}.log",
    shell:
        "samtools stats {input.bam} > {output.stats} 2> {log} && "
        "samtools flagstat {input.bam} > {output.flagstat} 2>> {log}"
