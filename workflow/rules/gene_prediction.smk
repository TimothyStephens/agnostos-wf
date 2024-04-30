rule gene_prediction:
    input:
        seqs = config['sequences']
    params:
        stage             = config["sequence_type"],
        prodigal_mode     = config["prodigal_mode"],
        prodigal_bin      = config["prodigal_bin"],
        sequences_partial = config["sequences_partial"],
        rename_orfs       = config["wdir"] + "/scripts/rename_orfs.awk",
        partial_info      = config["wdir"] + "/scripts/get_orf_partial_info.awk",
        gff_output        = config["rdir"] + "/gene_prediction/orfs_info.gff",
        tmp               = config["rdir"] + "/gene_prediction/tmpl"
    container:
        config["container_env"]
    output:
        fa      = config["rdir"] + "/gene_prediction/orf_seqs.fasta",
        partial = config["rdir"] + "/gene_prediction/orf_partial_info.tsv"
    log:
        config["rdir"] + "/logs/gene_prediction.log",
    benchmark:
        config["rdir"] + "/benchmarks/gene_prediction.tsv"
    shell:
        """
        (
        set -x
        set -e
        
        if [[ {params.stage} = "contigs" ]]; then
            
            {params.prodigal_bin} -i <(gunzip -fc {input.seqs}) -a {output.fa} -m -p {params.prodigal_mode} -f gff -o {params.gff_output} -q
            
            awk -f {params.rename_orfs} {output.fa} > {params.tmp} && mv {params.tmp} {output.fa}
            
            awk -f {params.partial_info} {params.gff_output} > {output.partial}
        
        elif [[ {params.stage} = "proteins" ]]; then
            
            ln -sf {input.seqs} {output.fa}
            
            ln -sf {params.sequences_partial} {output.partial}
        
        elif [[ {params.stage} = "anvio_genes" ]]; then
            
            ln -sf {input.seqs} {output.fa}
            
            awk -vOFS="\\t" 'NR>1{{if($6==0) print $1,"00"; else print $1,"11";}}' {params.sequences_partial} > {output.partial}
        
        fi
        ) 1>{log} 2>&1
        """

rule gene_prediction_done:
    input:
        fa      = config["rdir"] + "/gene_prediction/orf_seqs.fasta",
        partial = config["rdir"] + "/gene_prediction/orf_partial_info.tsv"
    output:
        gp_done = touch(config["rdir"] + "/gene_prediction/gp.done")
    run:
        shell("echo 'GP DONE'")
