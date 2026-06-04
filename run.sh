

mamba activate ~/miniforge3/envs/agnostos-wf_v2

snakemake -s Snakefile --use-conda --use-singularity --keep-going --printshellcmds --keep-incomplete --show-failed-logs \
  --singularity-args '--bind /home/timothy:/home/timothy --bind /scratch/timothy:/scratch/timothy' \
  --config module="creation" --cluster-config config/cluster.yaml -R \
  --until creation_workflow_report --rerun-incomplete -j 48 -n

snakemake -s Snakefile --use-conda --use-singularity --keep-going --printshellcmds --keep-incomplete --show-failed-logs \
  --singularity-args '--bind /home/timothy:/home/timothy --bind /scratch/timothy:/scratch/timothy' \
  --config module="update"   --cluster-config config/cluster.yaml -R \
  --until update_workflow_report   --rerun-incomplete -j 48 -n



