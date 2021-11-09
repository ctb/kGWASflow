# =================================================================================================
#     Generate kmers_list_paths.txt 
#     # This file contains a list of all individuals/samples k-mers list files and
#     # required to run kmersGWAS.
#     # For more info: https://github.com/voichek/kmersGWAS/blob/master/manual.pdf
# =================================================================================================

rule generate_kmers_list_paths:
    input:
        expand("results/kmers_count/{u.sample_name}/kmers_with_strand", u=samples.itertuples())
    output:
        "results/kmers_list/kmers_list_paths.txt"
    params:
        input_dir =  "results/kmers_count",
        out_dir = lambda wildcards, output: output[0][:-20]
    message:
        "Generating kmers_list_paths.txt..."
    shell:
        """
        python scripts/generate_kmers_list_paths.py -i {params.input_dir} -o {params.out_dir}
        """

# =================================================================================================
#     Combine and filter lists of kmers
# =================================================================================================

rule combine_and_filter:
    input:
        kmers_count =expand("results/kmers_count/{u.sample_name}/kmers_with_strand", u=samples.itertuples()),
        kmers_list = rules.generate_kmers_list_paths.output,
        kmersGWAS_bin = rules.extract_kmersGWAS.output.kmersGWAS_bin,
    output:
        kmers_to_use = protected("results/kmers_list/kmers_to_use"),
        shareness = "results/kmers_list/kmers_to_use.shareness"
    params:
        kmer_len = config["params"]["kmc"]["kmer_len"],
        mac = config["params"]["kmers_gwas"]["minor_allele_count"],
        min_app = config["params"]["kmers_gwas"]["min_percent_app"]
    conda:
        "../envs/kmers_gwas.yaml"
    message:
        "Combining the k-mers from each acession/sample into one list and filter the k-mers..."
    shell:
        """
        export LD_LIBRARY_PATH=$CONDA_PREFIX/lib

        {input.kmersGWAS_bin}/list_kmers_found_in_multiple_samples -l {input.kmers_list} -k {params.kmer_len} --mac {params.mac} -p {params.min_app} -o {output}
        """

# =================================================================================================
#     Plot k-mer allele counts
# =================================================================================================

rule plot_kmer_allele_counts:
    input:
        rules.combine_and_filter.output.shareness
    output:
        kmer_allele_counts_plot = report(
            "results/plots/kmers_list/kmer_allele_counts.pdf",
            caption="../report/plot_kmer_allele_counts.rst",
            category="k-mers Count Stats",
        )
    conda:
        "../envs/kmers_stats.yaml"
    message:
        "Plotting the k-mer allele counts..."
    shell:
        """
        python scripts/plot_kmer_allele_counts.py -i {input} -o {output.kmer_allele_counts_plot}
        """

# =================================================================================================