# Read quality control: FastQC on raw reads, fastp trimming, MultiQC summary


rule fastqc_raw:
    input:
        r1=lambda wc: SAMPLES.loc[wc.sample, "fq1"],
        r2=lambda wc: SAMPLES.loc[wc.sample, "fq2"],
    output:
        directory(f"{OUT}/qc/fastqc/{{sample}}"),
    log:
        f"{LOGS}/fastqc/{{sample}}.log",
    threads: 2
    shell:
        "mkdir -p {output} && fastqc --quiet --threads {threads} --outdir {output} {input.r1} {input.r2} > {log} 2>&1"


rule fastp:
    input:
        r1=lambda wc: SAMPLES.loc[wc.sample, "fq1"],
        r2=lambda wc: SAMPLES.loc[wc.sample, "fq2"],
    output:
        r1=f"{OUT}/trimmed/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/trimmed/{{sample}}_R2.fastq.gz",
        json=f"{OUT}/qc/fastp/{{sample}}.fastp.json",
        html=f"{OUT}/qc/fastp/{{sample}}.fastp.html",
    params:
        extra=config["fastp"]["extra"],
    log:
        f"{LOGS}/fastp/{{sample}}.log",
    threads: THREADS
    shell:
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} "
        "-j {output.json} -h {output.html} -w {threads} {params.extra} > {log} 2>&1"


rule multiqc:
    input:
        expand(f"{OUT}/qc/fastqc/{{sample}}", sample=SAMPLES.index),
        expand(f"{OUT}/qc/fastp/{{sample}}.fastp.json", sample=SAMPLES.index),
        expand(f"{OUT}/qc/markdup/{{sample}}.metrics.txt", sample=SAMPLES.index),
        expand(f"{OUT}/qc/samtools/{{sample}}.stats.txt", sample=SAMPLES.index),
        expand(f"{OUT}/qc/samtools/{{sample}}.flagstat.txt", sample=SAMPLES.index),
        expand(f"{OUT}/variants/{{sample}}.bcftools_stats.txt", sample=SAMPLES.index),
        expand(f"{OUT}/annotation/{{sample}}.vep_summary.html", sample=SAMPLES.index),
    output:
        f"{OUT}/qc/multiqc/multiqc_report.html",
    params:
        outdir=f"{OUT}/qc/multiqc",
    log:
        f"{LOGS}/multiqc/multiqc.log",
    shell:
        "multiqc --force --outdir {params.outdir} --filename multiqc_report.html {input} > {log} 2>&1"
