rule creation_workflow_report:
    input:
        cat_db  = config["rdir"] + "/cluster_category_DB/k_hhm_db.index",
        clu_cat = config["rdir"] + "/clusterDB_results/cluster_ids_categ.tsv.gz",
        comm    = config["rdir"] + "/cluster_communities/cluster_communities.tsv"
    threads: 28
    container:
        config["container_env"]
    params:
        basedir       = config["rdir"],
        sequence_type = config["sequence_type"],
        outdir        = config["rdir"] + "/report/",
        input_data    = config["sequences"],
        name_data     = config["data_name"],
        report_maker  = config["wdir"] + "/scripts/report_maker.r",
        wf_report     = config["wdir"] + "/scripts/creation_workflow_report.Rmd"
    output:
        report=config["rdir"] + "/report/workflow_report.html"
    log:
        config["rdir"] + "/logs/creation_workflow_report.log"
    benchmark:
        config["rdir"] + "/benchmarks/creation_workflow_report.tsv"
    shell:
        """
        (
        Rscript --vanilla {params.report_maker} --basedir {params.basedir} \
                                                --outdir  {params.outdir} \
                                                --stage {params.sequence_type} \
                                                --name {params.name_data} \
                                                --input {params.input_data} \
                                                --wf_report {params.wf_report} \
                                                --output {output.report}
        ) 1>{log} 2>&1
        """
