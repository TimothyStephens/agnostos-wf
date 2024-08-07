rule cluster_communities_dbs:
    input:
      k     = config["rdir"] + "/cluster_category_DB/k_hhm_db.index",
      stats = config["rdir"] + "/cluster_category_stats/cluster_category_summary_stats.tsv"
    threads: 7
    container:
      config["container_env"]
    params:
      mmseqs_bin = config["mmseqs_bin"],
      mpi_runner = config["mpi_runner_hmmer"],
      vmtouch    = config["vmtouch"],
      hhblits    = config["hhblits_bin_mpi"],
      hhparse    = config["wdir"] + "/scripts/categ_hhparser.sh",
      hhb_tmp_db = config["rdir"] + "/cluster_communities/hhbl_tmp",
    output:
      comm = config["rdir"] + "/cluster_communities/k_hhblits.tsv"
    log:
      config["rdir"] + "/logs/cluster_communities_dbs.log"
    benchmark:
      config["rdir"] + "/benchmarks/cluster_communities_dbs.tsv"
    shell:
      """
      (
      set -e
      set -x
      
      export OMPI_MCA_btl=^openib
      export OMP_NUM_THREADS={threads}
      export OMP_PROC_BIND=FALSE
      
      # HHblits all-clusters vs all-clusters for each category
      CATEG=$(echo -e "eu\ngu\nkwp\nk")
      
      IN=$(dirname {input.k})
      OUT=$(dirname {output.comm})
      
      for categ in $CATEG; do
        
        RES=${{OUT}}/${{categ}}_hhblits.tsv
        
        if [[ ! -s ${{RES}} ]]; then
            if [[ ! -s {params.hhb_tmp_db}.index  ]]; then
                {params.vmtouch} -f ${{IN}}/${{categ}}*
                {params.mpi_runner} {params.hhblits} -i ${{IN}}/${{categ}}_hhm_db \
                                                     -o {params.hhb_tmp_db} \
                                                     -n 2 -cpu 1 -v 0 \
                                                     -d ${{IN}}/${{categ}}
                mv {params.hhb_tmp_db}.ffdata {params.hhb_tmp_db}
                mv {params.hhb_tmp_db}.ffindex {params.hhb_tmp_db}.index
            fi
            {params.mpi_runner} {params.mmseqs_bin} apply {params.hhb_tmp_db} {params.hhb_tmp_db}.parsed \
                --threads 1 \
                -- {params.hhparse}
                
                sed -e 's/\\x0//g' {params.hhb_tmp_db}.parsed > ${{RES}}
                
                rm -rf {params.hhb_tmp_db} {params.hhb_tmp_db}.index {params.hhb_tmp_db}.dbtype {params.hhb_tmp_db}.parsed* {params.hhb_tmp_db}.ff*
        fi
      
      done
      ) 1>{log} 2>&1
      """

rule cluster_communities_inference:
    input:
      k     = config["rdir"] + "/cluster_communities/k_hhblits.tsv",
      stats = config["rdir"] + "/cluster_category_stats/cluster_category_summary_stats.tsv"
    threads: 7
    container:
      config["container_env"]
    params:
      get_comm    = config["wdir"] + "/" + "scripts/communities_inference/get_communities.R",
      pfam_clan   = config["ddir"] + "/" + config["pfam_clan"],
      db_mode     = config["db_mode"],
      comm_config = config["wdir"] + "/" + "config/config_communities.yaml"
    output:
      comm = config["rdir"] + "/cluster_communities/cluster_communities.tsv"
    log:
      config["rdir"] + "/logs/cluster_communities_inference.log"
    benchmark:
      config["rdir"] + "/benchmarks/cluster_communities_inference.tsv"
    shell:
      """
      (
      OUT=$(dirname {output.comm})
      
      if [ ! -s {params.pfam_clan} ]; then
        echo "Dowloading Pfam-A clan information"
        wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam34.0/Pfam-A.clans.tsv.gz -O {params.pfam_clan}
      fi
      
      # Start cluster community inference
      . /usr/local/etc/profile.d/conda.sh
      conda activate /usr/local/envs/cluster_communities_inference
      {params.get_comm} -c {params.comm_config}
      conda deactivate
      
      rm -rf ${{OUT}}/tmp
      
      if [[ {params.db_mode} == "memory" ]]; then
         rm {params.pfam_clan}
      fi
      ) 1>{log} 2>&1
      """

rule cluster_comm_done:
    input:
      comm = config["rdir"] + "/cluster_communities/cluster_communities.tsv"
    output:
      comm_done = touch(config["rdir"] + "/cluster_communities/comm.done")
    run:
      shell("echo 'COMMUNITIES INFERENCE DONE'")
