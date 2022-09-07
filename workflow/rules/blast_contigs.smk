# =======================================================================================================
#     Create a BLAST database
# =======================================================================================================

rule blast_makedb_nuc:
    input:
        fasta= "resources/genome.fasta"
    output:
        multiext("resources/genome.fasta",
            ".ndb",
            ".nhr",
            ".nin",
            ".not",
            ".nsq",
            ".ntf",
            ".nto"
        )
    log:
        "logs/blast_contigs/makeblastdb.log"
    params:
        "-input_type fasta -blastdb_version 5 -parse_seqids"
    wrapper:
        "v1.12.2/bio/blast/makeblastdb"

# =======================================================================================================
#     Filter out short contigs
# =======================================================================================================

rule filter_contigs:
    input:
        "results/assemble_reads_with_kmers/{phenos_filt}/assembly/contigs.fasta"
    output:
        "results/assemble_reads_with_kmers/{phenos_filt}/filtered_contigs/{phenos_filt}_contigs.filtered.fasta"
    conda:
        "../envs/align_reads.yaml"
    log:
        "logs/blast_contigs/filter_contigs/filter.{phenos_filt}_contigs.log"
    shell:
        """
        seqkit head -n 1 {input} > {output} 2> {log}
        """

# =======================================================================================================
#     BLAST longest contigs against reference db
# =======================================================================================================

rule blast_contigs:
    input:
        query = "results/assemble_reads_with_kmers/{phenos_filt}/filtered_contigs/{phenos_filt}_contigs.filtered.fasta",
        blastdb=multiext("resources/genome.fasta",
            ".ndb",
            ".nhr",
            ".nin",
            ".not",
            ".nsq",
            ".ntf",
            ".nto"
        )
    output:
        "results/blast_contigs/{phenos_filt}/{phenos_filt}_contigs.blast.txt"
    log:
        "logs/blast_contigs/{phenos_filt}_contigs.blast.log"
    threads: 
        config["params"]["blastn"]["threads"]
    params:
        format= config["params"]["blastn"]["format"],
        extra= config["params"]["blastn"]["extra"]
    wrapper:
        "v1.12.2/bio/blast/blastn"

# =========================================================================================================
#     Check extract_paired_reads 
# =========================================================================================================

def aggregate_input_blast_contigs(wildcards):
    checkpoint_output = checkpoints.fetch_kmers_from_res_table.get(**wildcards).output[0]
    return expand("results/blast_contigs/{phenos_filt}/{phenos_filt}_contigs.blast.txt",
           phenos_filt=glob_wildcards(os.path.join(checkpoint_output, "{phenos_filt}_kmers_list.txt")).phenos_filt)


rule check_blast_contigs:
    input:
        aggregate_input_blast_contigs
    output:
        "results/blast_contigs/blast_contigs.done"
    shell:
        """
        touch {output}
        """