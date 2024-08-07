rule cluster_functional_validation:
    input:
        cl_annot = config["rdir"] + "/annot_and_clust/annotated_clusters.tsv"
    threads: 28
    container:
        config["container_env"]
    params:
        funct_valr        = config["wdir"] + "/scripts/functional_validation.r",
        funct_val_fun     = config["wdir"] + "/scripts/funct_val_functions.r",
        pfam_shared_terms = config["ddir"] + "/" + config["pfam_shared_terms"],
        db_mode           = config["db_mode"]
    output:
        fval_res = config["rdir"] + "/validation/functional_val_results.tsv"
    log:
        config["rdir"] + "/logs/cluster_functional_validation.log",
    benchmark:
        config["rdir"] + "/benchmarks/cluster_functional_validation.tsv"
    shell:
        """
        (
        set -e
        set -x
        
        # Pfam list common domain terms
        if [ ! -s {params.pfam_shared_terms} ]; then
            echo "Dowloading Pfam list of shared domain names"
            wget https://figshare.com/ndownloader/files/31127782 -O {params.pfam_shared_terms}
        fi
        
        . /usr/local/etc/profile.d/conda.sh
        conda activate /usr/local/envs/functional_validation
        {params.funct_valr} --input {input.cl_annot} \
                            --pfam_terms {params.pfam_shared_terms} \
                            --output {output.fval_res} \
                            --functions {params.funct_val_fun} \
                            --threads {threads}
        conda deactivate
        
        if [[ {params.db_mode} == "memory" ]]; then
            rm {params.pfam_shared_terms}
        fi
        
        ) 1>{log} 2>&1
        """

rule cluster_fvalidation_done:
    input:
        fval_res = config["rdir"] + "/validation/functional_val_results.tsv"
    output:
        fval_done = touch(config['rdir'] + "/validation/fval.done")
    run:
        shell("echo 'FUNCTIONAL VALIDATION DONE'")
