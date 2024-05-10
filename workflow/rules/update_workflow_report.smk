rule update_workflow_report:
    input:
        iclu_com = config["rdir"] + "/integrated_cluster_DB/cluster_communities.tsv.gz",
        comm     = config["rdir"] + "/cluster_communities/cluster_communities.tsv",
        annot    = config["rdir"] + "/output_tables/DB_cluster_annotations.tsv"
    threads: 28
    container:
        config["container_env"]
    params:
        basedir       = config["rdir"],
        outdir        = config["rdir"] + "/report/",
        input_data    = config["data"],
        name_data     = config["data_name"],
        sequence_type = config["sequence_type"],
        report_maker  = config["wdir"] + "/scripts/report_maker.r",
        wf_report     = config["wdir"] + "/scripts/update_workflow_report.Rmd"
    output:
        report = config["rdir"] + "/report/workflow_report.html"
    log:
        config["rdir"] + "/logs/update_workflow_report.log"
    benchmark:
        config["rdir"] + "/benchmarks/update_workflow_report.tsv"
    shell:
        """
        (
        . /usr/local/etc/profile.d/conda.sh
        conda activate /usr/local/envs/report_maker
        Rscript --vanilla {params.report_maker} --basedir {params.basedir} \
                                                --outdir  {params.outdir} \
                                                --name {params.name_data} \
                                                --input {params.input_data} \
                                                --stage {params.sequence_type} \
                                                --wf_report {params.wf_report} \
                                                --output {output.report}
        conda deactivate
        ) 1>{log} 2>&1
        """
