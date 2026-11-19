# Reference genome and annotation preparation


rule decompress_reference:
    input:
        config["reference"]["fasta_gz"],
    output:
        REF,
    log:
        f"{LOGS}/reference/decompress.log",
    shell:
        "gzip -dc {input} > {output} 2> {log}"


rule faidx_reference:
    input:
        REF,
    output:
        f"{REF}.fai",
    log:
        f"{LOGS}/reference/faidx.log",
    shell:
        "samtools faidx {input} 2> {log}"


rule sequence_dictionary:
    input:
        REF,
    output:
        REF_DICT,
    log:
        f"{LOGS}/reference/dict.log",
    shell:
        "gatk CreateSequenceDictionary -R {input} -O {output} > {log} 2>&1"


rule bwa_mem2_index:
    input:
        REF,
    output:
        multiext(REF, ".0123", ".amb", ".ann", ".bwt.2bit.64", ".pac"),
    log:
        f"{LOGS}/reference/bwa_mem2_index.log",
    shell:
        "bwa-mem2 index {input} > {log} 2>&1"


rule prepare_gff:
    """VEP needs a coordinate-sorted, bgzipped and tabix-indexed GFF3."""
    input:
        config["annotation"]["gff3_gz"],
    output:
        gff=GFF,
        tbi=f"{GFF}.tbi",
    log:
        f"{LOGS}/reference/prepare_gff.log",
    shell:
        """
        (gzip -dc {input} | grep -v '^#' \
            | sort -t$'\\t' -k1,1 -k4,4n -k5,5n \
            | bgzip -c > {output.gff}) 2> {log}
        tabix -p gff {output.gff} 2>> {log}
        """
