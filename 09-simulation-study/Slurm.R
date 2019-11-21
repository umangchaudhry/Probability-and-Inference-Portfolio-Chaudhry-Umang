#!/bin/bash
#SBATCH --mail-user=umang.chaudhry@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --ntasks=1
#SBATCH --time=04:00:00
#SBATCH --mem=4G
#SBATCH --array=1-16
#SBATCH --output=./out/out_%a.out

#Rscript simulation.R $SLURM_ARRAY_TASK_ID