rule cluster_updt_pfam_annotation:
    input:
        clu     = config["rdir"] + "/mmseqs_clustering/cluDB_no_singletons.tsv",
        annot   = config["rdir"] + "/pfam_annotation/pfam_annot_parsed.tsv",
        partial = config["rdir"] + "/gene_prediction/orf_partial_info.tsv"
    priority: 1
    threads: 28
    container:
        config["container_env"]
    params:
        cl_annotr      = config["wdir"] + "/scripts/clu_annot.r",
        pfam_clan      = config["ddir"] + "/" + config["pfam_clan"],
        local_tmp      = config["mmseqs_local_tmp"],
        db_mode        = config["db_mode"],
        singl          = config["rdir"] + "/mmseqs_clustering/cluDB_singletons.tsv",
        s_annot        = config["rdir"] + "/annot_and_clust/singletons_pfam_annot.tsv",
        or_multi_annot = config["ordir"] + "/pfam_name_acc_clan_multi.tsv.gz",
        multi_annot    = config["rdir"] + "/annot_and_clust/pfam_name_acc_clan_multi.tsv",
        or_partial     = config["ordir"] + "/orf_partial_info.tsv.gz",
        partial        = config["rdir"] + "/annot_and_clust/new_orf_partial_info.tsv",
        tmp            = config["rdir"] + "/annot_and_clust/tmp",
        concat         = config["wdir"] + "/scripts/concat_multi_annot.awk"
    output:
        cl_annot   = config["rdir"] + "/annot_and_clust/annotated_clusters.tsv",
        cl_noannot = config["rdir"] + "/annot_and_clust/not_annotated_clusters.tsv"
    log:
        config["rdir"] + "/logs/cluster_updt_pfam_annotation.log"
    benchmark:
        config["rdir"] + "/benchmarks/cluster_updt_pfam_annotation.tsv"
    shell:
        """
        (
        set -e
        set -x
        
        ## 1. Pfam-clan info and multi-domain format for the ORF Pfam annotations
        # Download original dataset Pfam annotations
        if [[ ! -s {params.or_multi_annot} ]]; then
            wget https://ndownloader.figshare.com/files/23067146 -O {params.or_multi_annot}
        fi
        
        if [ ! -s {params.pfam_clan} ]; then
            echo "Dowloading Pfam-A clan information"
            wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam34.0/Pfam-A.clans.tsv.gz -O {params.pfam_clan}
        fi
        
        # Add Pfam clan info to the Pfam annotation results
        join -11 -21 \
            <( awk '{{print $1,$3,$8,$9}}' {input.annot} | sort -k1,1) \
            <( zcat {params.pfam_clan} | awk -vFS='\\t' -vOFS='\\t' '{{print $4,$1,$2}}' \
          | awk -vFS='\\t' -vOFS='\\t' '{{for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = "no_clan"}};1' \
          | sort -k1,1) \
          > {params.multi_annot}
        
        if [[ {params.db_mode} == "memory" ]]; then
            rm {params.pfam_clan}
        fi
        
        # Reorder columns
        # the previous output is: pfam_name - orf - start - end - pfam_acc - pfam_clan
        # we want to get: orf - pfam_name - pfam_acc - pfam_clan - start - end
        awk -vOFS='\\t' '{{print $2,$1,$5,$6,$3,$4}}' {params.multi_annot} > {params.tmp} && mv {params.tmp} {params.multi_annot}
        
        # Multiple annotations on the same line, separated by “|” (the annotations were ordered first by alignment position)
        sort -k1,1 -k5,6g {params.multi_annot} \
          | awk -vFS='\\t' -vOFS='\\t' '{{print $1,$2,$3,$4}}' | sort -k1,1 \
          | awk -f {params.concat} | sed 's/ /\t/g' \
          > {params.tmp}
        
        mv {params.tmp} {params.multi_annot}
        
        zcat {params.or_multi_annot} | sed 's/ /\\t/g' >> {params.multi_annot}
        
        # Gene completeness information combined
        # Download original dataset gene completion information
        if [[ ! -s {params.or_partial} ]]; then
            wget https://ndownloader.figshare.com/files/23067005 -O {params.or_partial}
        fi
        
        # Combine with new completion info
        join -11 -21 \
            <(sort -k1,1 --parallel={threads} -T {params.local_tmp} {input.partial}) \
            <( awk '{{print $3}}' {input.clu} | sort -k1,1 --parallel={threads}) \
          > {params.partial}
        join -11 -21 \
            <(zcat {params.or_partial} | sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
            <(awk '{{print $3}}' {input.clu} | sort -k1,1 --parallel={threads}) \
          >> {params.partial}
        
        sed -i 's/ /\\t/g' {params.partial}
        
        ## 2. Cluster annotations
        
        # The r script "clu_annot.r" distribute the Pfam annotation in the clusters,
        # creating two sets: "annotated_clusters" and "not_annotated_clusters"
        . /usr/local/etc/profile.d/conda.sh
        conda activate /usr/local/envs/clu_annot
        {params.cl_annotr} --pfam_annot {params.multi_annot} \
                           --clusters {input.clu} \
                           --partial {params.partial} \
                           --output_annot {output.cl_annot} \
                           --output_noannot {output.cl_noannot}
        conda deactivate
        
        ## 3. Singleton annotations
        
        join -12 -21 \
            <(sort -k2,2 {params.singl} ) \
            <(sort -k1,1 --parallel={threads} -T {params.local_tmp} {params.multi_annot}) \
          > {params.s_annot}
        
        gzip -f {params.multi_annot}
        
        ) 1>{log} 2>&1
        """

rule cluster_pfam_annotation_done:
    input:
        cl_annot   = config["rdir"] + "/annot_and_clust/annotated_clusters.tsv",
        cl_noannot = config["rdir"] + "/annot_and_clust/not_annotated_clusters.tsv"
    output:
        annot_done = touch(config["rdir"] + "/annot_and_clust/cl_annot.done")
    run:
        shell("echo 'CLUSTER PFAM ANNOTATION DONE'")
