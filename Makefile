CORES ?= 4
IMAGE ?= wes-wgs-demo

.PHONY: help env data dryrun run dag notebook clean docker-build docker-run

help:            ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

env:             ## Create the conda environment
	conda env create -f environment.yml

data:            ## Download the public test data
	bash scripts/download_data.sh

dryrun:          ## Show the jobs Snakemake would run
	snakemake -n --cores $(CORES) --use-conda

run:             ## Run the full pipeline
	snakemake --cores $(CORES) --use-conda --printshellcmds

dag:             ## Render the rule graph (needs graphviz `dot`)
	snakemake --rulegraph | dot -Tsvg > docs/rulegraph.svg

notebook:        ## Execute the integration notebook in place
	jupyter nbconvert --to notebook --execute --inplace notebooks/01_integrate_variants_metadata.ipynb

clean:           ## Remove pipeline outputs (keeps downloaded data and the VEP env)
	rm -rf results logs

docker-build:    ## Build the Docker image
	docker build -t $(IMAGE) .

docker-run:      ## Download data and run the pipeline inside Docker
	docker run --rm -v "$(PWD)":/work $(IMAGE) bash scripts/download_data.sh
	docker run --rm -v "$(PWD)":/work $(IMAGE) snakemake --cores $(CORES) --use-conda
