import multiprocessing
import os
import pandas as pd

# Get the number of CPUs
CPUS = multiprocessing.cpu_count()
# Get the available memory for trinity settings
mem_available = os.sysconf('SC_PAGE_SIZE')*os.sysconf('SC_AVPHYS_PAGES')
MEMORY = str(mem_available//(1024**3))+"G"

configfile: "config.yaml"
# Read the samples.csv configuration file for sample names
sample_table = pd.read_table(config["SAMPLES"], header=None)
sample_header = ["Sample","Rep","Fastq1","Fastq2"]
sample_table.columns = sample_header[:len(sample_table.columns)]
sample_list = sample_table.iloc[:,2:].values.flatten('F')
file_ext = dict()
for s in sample_list:	
	num = 2 if s.endswith(".gz") else 1
	splitted = s.split(".")
	file_ext[".".join(splitted[:-num])] = ".".join(splitted[-num:])

rule all:
	input:
		expand("{basename}_fastqc.html",basename=file_ext),
		"trinity_out_dir/Trinity.fasta"		

rule fastqc:
### FastQC analysis
	input:
		lambda wildcards: wildcards.basename+"."+file_ext[wildcards.basename]
	output:
		"{basename}_fastqc.html"
	params:
		extra = config["EXTRA_PARAMS"]["fastqc"]
	shell:
		"fastqc {input} {params.extra}"

rule trinity:
### Trinity assembly
	input:
		sample_list
	output:
		"trinity_out/Trinity.fasta"
	threads: CPUS
	params:
		extra = config["EXTRA_PARAMS"]["trinity"],
		memory = MEMORY
	shell:
		"Trinity --CPU {threads} --max_memory {params.memory} --samples_file samples.csv {params.extra}"
