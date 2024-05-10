rule cluster_validation_results:
      input:
        cval = config["rdir"] + "/validation/compositional_validation_results.tsv",
        fval = config["rdir"] + "/validation/functional_val_results.tsv"
      threads: 28
      container:
        config["container_env"]
      params:
        cl_annot   = config["rdir"] + "/annot_and_clust/annotated_clusters.tsv",
        cl_noannot = config["rdir"] + "/annot_and_clust/not_annotated_clusters.tsv",
        val_res    = config["wdir"] + "/scripts/validation_summary.r",
        val_annot  = config["rdir"] + "/validation/validation_annot_noannot.tsv",
        val_stats  = config["rdir"] + "/validation/validation_results_stats.tsv",
        val_plots  = config["rdir"] + "/validation/validation_plots_for_R.rda",
        tmp        = config["rdir"] + "/validation/tmp"
      output:
        val_res = config["rdir"] + "/validation/validation_results.tsv",
        good = config["rdir"] + "/validation/good_clusters.tsv"
      log:
        config["rdir"] + "/logs/cluster_validation_results.log",
      benchmark:
        config["rdir"] + "/benchmarks/cluster_validation_results.tsv"
      shell:
        """
        (
        set -e
        set -x
        
        # Retrieve old cluster representatives information
        #  - Not annotated clusters
        join -11 -21 <(awk '{{print $1,$2}}' {input.cval} | sort -k1,1 --parallel={threads}) \
          <(awk '!seen[$1]++{{print $1,$2,"noannot",$4}}' {params.cl_noannot} | sort -k1,1 --parallel={threads}) > {params.val_annot}
        # Annotated clusters
        join -11 -21 <(awk '{{print $1,$2}}' {input.cval} | sort -k1,1 --parallel={threads}) \
          <(awk '!seen[$1]++{{print $1,$2,"annot",$4}}' {params.cl_annot} | sort -k1,1 --parallel={threads} ) >> {params.val_annot}
        
        awk -vOFS='\\t' '{{print $1,$2,$3,$5,$4}}'  {params.val_annot} \
          > {params.tmp} && mv {params.tmp} {params.val_annot}
        
        # Combine with functional validation results
        . /usr/local/etc/profile.d/conda.sh
        conda activate /usr/local/envs/validation_summary
        {params.val_res} --fval_res {input.fval} \
                         --cval_res {input.cval} \
                         --val_annot {params.val_annot} \
                         --val_res {output.val_res} \
                         --val_stats {params.val_stats} \
                         --good {output.good} \
                         --plots {params.val_plots}
        conda deactivate
        
        rm -rf {params.val_annot} {params.tmp}
        ) 1>{log} 2>&1
        """

rule cluster_validation_done:
    input:
        val_res = config["rdir"] + "/validation/validation_results.tsv",
        good = config["rdir"] + "/validation/good_clusters.tsv"
    output:
        val_done = touch(config["rdir"] + "/validation/val.done")
    run:
        shell("echo 'CLUSTER VALIDATION DONE'")
