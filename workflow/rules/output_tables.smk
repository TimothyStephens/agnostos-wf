rule output_tables:
    input:
        genes = config["rdir"] + "/gene_prediction/orf_partial_info.tsv",
        cat = config["rdir"] + "/integrated_cluster_DB/cluster_ids_categ.tsv.gz"
    threads: 28
    container:
        config["container_env"]
    params:
        contig        = config["rdir"] + "/output_tables/contig_genes.tsv",
        new_data_name = config["data_name"],
        sequence_type = config["sequence_type"],
        orig_db       = config["ordir"],
        clu_info      = config["rdir"] + "/mmseqs_clustering/cluDB_info.tsv",
        clu_origin    = config["rdir"] + "/integrated_cluster_DB/cluDB_name_origin_size.tsv.gz",
        comm          = config["rdir"] + "/integrated_cluster_DB/cluster_communities.tsv.gz",
        hq_clu        = config["rdir"] + "/integrated_cluster_DB/HQ_clusters.tsv.gz",
        k_annot       = config["rdir"] + "/integrated_cluster_DB/K_annotations.tsv.gz",
        kwp_annot     = config["rdir"] + "/integrated_cluster_DB/KWP_annotations.tsv.gz",
        gu_annot      = config["rdir"] + "/integrated_cluster_DB/GU_annotations.tsv.gz",
        singl         = config["singl"],
        singl_cat     = config["rdir"] + "/integrated_cluster_DB/singleton_gene_cl_categories.tsv.gz",
        parser        = config["wdir"] + "/scripts/output_tables.r"
    output:
        res   = config["rdir"] + "/output_tables/DB_genes_summary_info_exp.tsv",
        annot = config["rdir"] + "/output_tables/DB_cluster_annotations.tsv"
    log:
        config["rdir"] + "/logs/output_tables.log"
    benchmark:
        config["rdir"] + "/benchmarks/output_tables.tsv"
    shell:
        """
        (
        set -x
        set -e
        
        DB=$(basename {params.orig_db})
        
        if [[ ${{DB}} == "agnostosDB" ]]; then
            # Download agnostosDB ecological analysis data
            wget https://ndownloader.figshare.com/files/23066879 -O ecological.tar.gz
            tar -xzvf ecological.tar.gz
            
            # Download agnostosDB phylogentic analysis data
            wget https://ndownloader.figshare.com/files/23066864 -O phylogenetic.tar.gz
            tar -xzvf phylogenetic.tar.gz
            
            # Download agnostosDB experimental analysis data
            wget https://ndownloader.figshare.com/files/23066864 -O phylogenetic.tar.gz
            tar -xzvf experimental.tar.gz
        fi
        
        # Run R script to retrieve a general table containing a summary of the integration
        # add contextual data if the original DB is the agnostosDB
        awk -vOFS='\\t' '{{split($1,a,"_\\\+|_-"); print a[1],$1}}' {input.genes} > {params.contig}
        
        . /usr/local/etc/profile.d/conda.sh
        conda activate /usr/local/envs/output_tables
        {params.parser} --clu_or {params.clu_origin} \
                        --contig {params.contig} \
                        --cat {input.cat} \
                        --clu_info {params.clu_info} \
                        --name {params.new_data_name} \
                        --comm {params.comm} \
                        --hq_clu {params.hq_clu} \
                        --k_annot {params.k_annot} \
                        --kwp_annot {params.kwp_annot} \
                        --gu_annot {params.gu_annot} \
                        --orig_db {params.orig_db} \
                        --is_singl {params.singl} \
                        --s_categ {params.singl_cat} \
                        --anvio {params.sequence_type} \
                        --threads {threads}
        conda deactivate
        
        ) 1>{log} 2>&1
        """

rule output_tables_done:
    input:
        res   = config["rdir"] + "/output_tables/DB_genes_summary_info_exp.tsv",
        annot = config["rdir"] + "/output_tables/DB_cluster_annotations.tsv"
    output:
        res_done = touch(config["rdir"] + "/output_tables/res.done")
    run:
        shell("echo 'Parsing of results DONE'")
