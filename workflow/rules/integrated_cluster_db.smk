rule integrated_cluster_db:
    input:
        clu_cat   = config["rdir"] + "/cluster_categories/cluster_ids_categ.tsv",
        clu_com   = config["rdir"] + "/cluster_communities/cluster_communities.tsv",
        clu_stats = config["rdir"] + "/cluster_category_stats/cluster_category_summary_stats.tsv",
        hq_clu    = config["rdir"] + "/cluster_category_stats/HQ_clusters.tsv",
        clu_hhm   = config["rdir"] + "/cluster_category_DB/clu_hhm_db"
    threads: 7
    container:
        config["container_env"]
    params:
        mmseqs_bin          = config["mmseqs_bin"],
        mmseqs_tmp          = config["mmseqs_tmp"],
        local_tmp           = config["mmseqs_local_tmp"],
        idir                = config["rdir"] + "/integrated_cluster_DB",
        data_name           = config["data_name"],
        eval_shared         = config["eval_shared"],
        integr_comm         = config["wdir"] + "scripts/integrate_communities.R",
        original            = config["rdir"] + "/mmseqs_clustering/cluDB_original_name_rep_size.tsv",
        shared              = config["rdir"] + "/mmseqs_clustering/cluDB_shared_name_rep_size.tsv",
        new                 = config["rdir"] + "/mmseqs_clustering/cluDB_new_name_rep_size.tsv",
        new_cluseqdb        = config["rdir"] + "/mmseqs_clustering/new_clu_seqDB",
        all                 = config["rdir"] + "/mmseqs_clustering/cluDB_all_name_rep_size.tsv",
        final               = config["rdir"] + "/mmseqs_clustering/cluDB_name_rep_size.tsv",
        clu_info            = config["rdir"] + "/mmseqs_clustering/cluDB_info.tsv",
        tmpl1               = config["rdir"] + "/integrated_cluster_DB/tmpl1",
        tmpl2               = config["rdir"] + "/integrated_cluster_DB/tmpl2",
        clu_seq             = config["rdir"] + "/cluster_refinement/refined_clusterDB",
        clu_gene            = config["rdir"] + "/cluster_categories/cluster_ids_categ_genes.tsv.gz",
        sp_sh               = config["rdir"] + "/spurious_shadow/spurious_shadow_info.tsv",
        multi_annot         = config["rdir"] + "/annot_and_clust/pfam_name_acc_clan_multi.tsv.gz",
        partial             = config["rdir"] + "/gene_prediction/orf_partial_info.tsv",
        isp_sh              = config["rdir"] + "/integrated_cluster_DB/spurious_shadow_info.tsv.gz",
        imulti_annot        = config["rdir"] + "/integrated_cluster_DB/pfam_name_acc_clan_multi.tsv.gz",
        ipartial            = config["rdir"] + "/integrated_cluster_DB/orf_partial_info.tsv.gz",
        iclu_gene           = config["rdir"] + "/integrated_cluster_DB/cluster_ids_categ_genes.tsv.gz",
        iclu_hhm            = config["rdir"] + "/integrated_cluster_DB/mmseqs-profiles/clu_hhm_db",
        clu_origin          = config["rdir"] + "/integrated_cluster_DB/cluDB_name_origin_size.tsv",
        or_dir              = config["ordir"],
        or_clu_orig         = config["ordir"] + "/cluDB_name_origin_size.tsv.gz",
        or_clu_cat          = config["ordir"] + "/cluster_ids_categ.tsv.gz",
        or_clu_gene         = config["ordir"] + "/cluster_ids_categ_genes.tsv.gz",
        or_clu_com          = config["ordir"] + "/cluster_communities.tsv.gz",
        or_clu_stats        = config["ordir"] + "/cluster_category_summary_stats.tsv.gz",
        or_hq_clu           = config["ordir"] + "/HQ_clusters.tsv.gz",
        or_profiles         = config["ordir"] + "/mmseqs-profiles",
        or_clu_hhm          = config["ordir"] + "/mmseqs-profiles/clu_hhm_db",
        or_partial          = config["ordir"] + "/orf_partial_info.tsv.gz",
        or_singl            = config["ordir"] + "/singleton_gene_cl_categories.tsv.gz",
        singl               = config["singl"],
        s_categ             = config["rdir"] + "/cluster_classification/singleton_gene_cl_categories.tsv",
        singl_cl_gene_categ = config["rdir"] + "/integrated_cluster_DB/singleton_gene_cl_categories.tsv"
    log:
        config["rdir"] + "/logs/integrated_cluster_db.log"
    benchmark:
        config["rdir"] + "/benchmarks/integrated_cluster_db.tsv"
    output:
        iclu_cat   = config["rdir"] + "/integrated_cluster_DB/cluster_ids_categ.tsv.gz",
        iclu_com   = config["rdir"] + "/integrated_cluster_DB/cluster_communities.tsv.gz",
        iclu_stats = config["rdir"] + "/integrated_cluster_DB/cluster_category_summary_stats.tsv.gz",
        ihq_clu    = config["rdir"] + "/integrated_cluster_DB/HQ_clusters.tsv.gz",
        iclu_hmm   = config["rdir"] + "/integrated_cluster_DB/mmseqs-profiles/clu_profileDB",
    shell:
        """
        (
        set -x
        set -e
        
        DIR=$(dirname {output.iclu_hmm})
        
        mkdir -p ${{DIR}}
        
        if [[ ! -s {params.or_clu_orig} ]]; then
            wget https://ndownloader.figshare.com/files/23066966 -O {params.or_clu_orig}
        fi
        
        # Summary table with cluster db origin (original/shared/new)
        join -11 -21 \
            <(zcat {params.or_clu_orig} | awk '{{print $1,$2}}' | sort -k1,1 --parallel={threads} ) \
            <(awk '{{print $1,$3}}' {params.original} | sort -k1,1) \
          > {params.clu_origin}
        join -11 -21 \
            <(zcat {params.or_clu_orig} | awk '{{print $1,$2}}' |  sort -k1,1 --parallel={threads} ) \
            <(awk '{{print $1,$3}}' {params.shared} | sort -k1,1) \
          > {params.clu_origin}.temp
        awk -vN={params.data_name} '{{print $1,$2"_"N,$3}}' {params.clu_origin}.temp >> {params.clu_origin}
        awk -vN={params.data_name} '{{print $1,N,$3}}' {params.new} >> {params.clu_origin}
        rm {params.clu_origin}.temp
        sed -i 's/ /\t/g' {params.clu_origin}
        gzip {params.clu_origin}
        # Clean the mmseqs_clustering/ folder
        mv {params.all} {params.final}
        
        rm {params.original} {params.shared} {params.new} {params.new_cluseqdb}*
        
        # All gene headers and partiality information
        cat {params.partial} <(zcat {params.or_partial}) | gzip > {params.ipartial}
        
        # Spurious and shadow genes information:
        gzip -c {params.sp_sh} > {params.isp_sh}
        
        # All gene Pfam annotations:
        cp {params.multi_annot} {params.imulti_annot}
        
        # All cluster category annotation files
        ODIR=$(dirname {params.or_clu_cat})
        NDIR=$(dirname {input.clu_cat})
        
        # Download original dataset category annotations
        if [[ ! -s ${{ODIR}}/K_annotations.tsv.gz ]]; then
            wget https://ndownloader.figshare.com/files/23063648 -O ${{ODIR}}/K_annotations.tsv.gz
            wget https://ndownloader.figshare.com/files/23067074 -O ${{ODIR}}/KWP_annotations.tsv.gz
            wget https://ndownloader.figshare.com/files/23067080 -O ${{ODIR}}/GU_annotations.tsv.gz
        fi
        
        # Combine with new ones
        cat <(zcat ${{ODIR}}/K_annotations.tsv.gz) ${{NDIR}}/K_annotations.tsv | gzip > {params.idir}/K_annotations.tsv.gz
        cat <(zcat ${{ODIR}}/KWP_annotations.tsv.gz) ${{NDIR}}/KWP_annotations.tsv | gzip > {params.idir}/KWP_annotations.tsv.gz
        cat <(zcat ${{ODIR}}/GU_annotations.tsv.gz) ${{NDIR}}/GU_annotations.tsv | gzip > {params.idir}/GU_annotations.tsv.gz
        # rm ${{ODIR}}/*_annotations.tsv.gz
        
        # Integrated set of cluster categories
        # Download original gene cluster catgeory info
        if [[ ! -s {params.or_clu_cat} ]]; then
            wget https://ndownloader.figshare.com/files/23067140 -O {params.or_clu_cat}
        fi
        
        # and the cluster genes
        # Download original gene cluster catgeory info
        if [[ ! -s {params.or_clu_gene} ]]; then
            wget https://ndownloader.figshare.com/files/24121865 -O {params.or_clu_gene}
        fi
        
        if [[ {params.eval_shared} == "true" ]]; then
            # GC-categories
            join -11 -21 -v1 \
                <(zcat {params.or_clu_cat} sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
                <(sort -k1,1 --parallel={threads} -T {params.local_tmp} {input.clu_cat}) \
              > {params.tmpl2}
            sed -i 's/ /\\t/g' {params.tmpl2}
            cat {params.tmpl2} {input.clu_cat} | gzip > {output.iclu_cat}
            
            # GC-genes-categories: get the new genes in the good clusters (shared)
            # remove shared GCs from the old table
            join -11 -21 -v1 \
                <(zcat {params.or_clu_gene} sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
                <(sort -k1,1 --parallel={threads} -T {params.local_tmp} {input.clu_cat}) \
              > {params.tmpl1}
            sed -i 's/ /\\t/g' {params.tmpl1}
            cat {params.tmpl1} <(zcat {params.clu_gene}) | gzip > {params.iclu_gene}
            
            rm {params.tmpl1}
        else
            # GC-categories
            cat <(zcat {params.or_clu_cat}) {input.clu_cat} | gzip > {output.iclu_cat}
            
            # GC-genes-categories: get the new genes in the good clusters (shared)
            ### double join, first cluDB_info, then orf_seqs.txt to get the new ones only
            join -11 -21 \
                <(zcat {params.or_clu_cat} | sort -k1,1) \
                <(awk '{{print $1,$3}}' {params.clu_info} | sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
              > {params.tmpl1}
            join -13 -21 \
                <(sort -k3,3 --parallel={threads} -T {params.local_tmp} {params.tmpl1}) \
                <(sort -k1,1 <(awk '{{print $1}}' {params.partial})) \
              > {params.tmpl2}
            # add to original clu genes and new clu genes
            cat <(awk -vOFS='\\t' '{{print $2,$3,$1}}' {params.tmpl2}) \
                <(zcat {params.or_clu_gene}) \
              > {params.tmpl1}
            cat {params.tmpl1} <(zcat {params.clu_gene}) | gzip > {params.iclu_gene}
            rm {params.tmpl1} {params.tmpl2}
        fi
        
        if [ {params.singl} == "true" ]; then
            if [[ ! -s {params.or_singl} ]]; then
                wget https://figshare.com/ndownloader/files/31012435 -O {params.or_singl}
            fi
            join -11 -21 \
                <(zcat {params.clu_origin}.gz | awk '$3==1{{print $1}}' sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
                <(zcat {params.or_singl} | sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
              > {params.tmpl1}
            
            cat \
                <(sed 's/ /\t/g' {params.tmpl1}) \
                <( awk -vOFS="\\t" '{{print $2,$3,$1}}' {params.s_categ}) \
              > {params.singl_cl_gene_categ}
            
            gzip {params.singl_cl_gene_categ}
         fi
        
        # Integrated set of cluster communities
        # to avoid having overlapping communities names, the dataset origin is appended to the name
        if [[ ! -s {params.or_clu_com} ]]; then
            wget https://ndownloader.figshare.com/files/23067134 -O {params.or_clu_com}
        fi
        
        {params.integr_comm} --name {params.data_name} \
                             --comm {input.clu_com} \
                             --ocomm {params.or_clu_com} \
                             --icomm {output.iclu_com} \
                             --shared {params.eval_shared}
        
        gzip {output.iclu_com}
        
        # Integrated cluster summary information
        if [[ ! -s {params.or_clu_stats} ]]; then
            wget https://figshare.com/ndownloader/files/31003162 -O {params.or_clu_stats}
        fi
        if [[ {params.eval_shared} == "true" ]]; then
            join -11 -21 -v1 \
                <(zcat {params.or_clu_stats} | sort -k1,1 --parallel={threads} -T {params.local_tmp}) \
                <(sort -k1,1 --parallel={threads} -T {params.local_tmp} {input.clu_stats}) \
              > {params.tmpl1}
            sed -i 's/ /\\t/g' {params.tmpl1}
            cat {input.clu_stats} {params.tmpl1} | gzip > {output.iclu_stats}
        else
            cat {input.clu_stats} <(zcat {params.or_clu_stats} | awk -vOFS='\\t' 'NR>1{{print $0}}') | gzip > {output.iclu_stats}
        fi
        
        # Integrated set of high quality (HQ) clusters
        if [[ ! -s {params.or_hq_clu} ]]; then
            wget https://ndownloader.figshare.com/files/23067137 -O {params.or_hq_clu}
        fi
        
        if [[ {params.eval_shared} == "true" ]]; then
            join -11 -21 -v1 \
                <(zcat {params.or_hq_clu} | sort -k1,1 ) \
                <(sort -k1,1 {input.hq_clu}) \
              > {params.tmpl1}
            sed -i 's/ /\\t/g' {params.tmpl1}
            cat {input.hq_clu} {params.tmpl1} | gzip > {output.ihq_clu}
        else
            cat {input.hq_clu} <(zcat {params.or_hq_clu} | awk -vOFS='\\t' 'NR>1{{print $0}}' ) | gzip > {output.ihq_clu}
        fi
        
        # New integarted cluster HMMs DB (for MMseqs profile searches)
        # Download and uncompress the existing GC profiles
        if [[ ! -s {params.or_clu_hhm} ]]; then
            wget https://figshare.com/ndownloader/files/30998305 -O {params.or_profiles}.tar.gz
            tar -C {params.or_dir} -xzvf {params.or_profiles}.tar.gz
            rm {params.or_profiles}.tar.gz
        fi
        
        if [[ {params.eval_shared} == "true" ]]; then
            {params.mmseqs_bin} createsubdb \
                <(awk '{{print $1}}' {params.tmpl2}) \
                {params.or_clu_hhm} \
                {params.or_clu_hhm}.left
            {params.mmseqs_bin} concatdbs \
                {input.clu_hhm} \
                {params.or_clu_hhm}.left \
                {params.iclu_hhm} \
                    --threads 1 --preserve-keys
            # Create a comprehensive profile cluster DB in MMseqs format to perform profile searches
            {params.mmseqs_bin} convertprofiledb \
                {params.iclu_hhm} \
                {output.iclu_hmm} \
                    --threads {threads}
            rm {params.or_clu_hhm}.left*
        else
            {params.mmseqs_bin} concatdbs \
                {input.clu_hhm} \
                {params.or_clu_hhm} \
                {params.iclu_hhm} \
                    --threads 1 --preserve-keys
            # Create a comprehensive profile cluster DB in MMseqs format to perform profile searches
            {params.mmseqs_bin} convertprofiledb \
                {params.iclu_hhm} \
                {output.iclu_hmm} \
                    --threads {threads}
        fi
        ) 1>{log} 2>&1
        """

rule integrated_cludb_done:
    input:
        iclu_cat   = config["rdir"] + "/integrated_cluster_DB/cluster_ids_categ.tsv.gz",
        iclu_com   = config["rdir"] + "/integrated_cluster_DB/cluster_communities.tsv.gz",
        iclu_stats = config["rdir"] + "/integrated_cluster_DB/cluster_category_summary_stats.tsv.gz",
        ihq_clu    = config["rdir"] + "/integrated_cluster_DB/HQ_clusters.tsv.gz",
        iclu_hmm   = config["rdir"] + "/integrated_cluster_DB/mmseqs-profiles/clu_hmm_db"
    output:
        integdb_done = touch(config["rdir"] + "/integrated_cluster_DB/integdb.done")
    run:
        shell("echo 'INTEGRATED DB DONE'")
