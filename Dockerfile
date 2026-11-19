# Container with the main environment (environment.yml). The VEP environment
# (workflow/envs/vep.yml) is built by Snakemake on first run via --use-conda and
# cached in .snakemake/conda/ inside the mounted project folder.
#
#   docker build -t wes-wgs-demo .
#   docker run --rm -v "$PWD":/work wes-wgs-demo bash scripts/download_data.sh
#   docker run --rm -v "$PWD":/work wes-wgs-demo snakemake --cores 4 --use-conda
#
# On Apple Silicon add --platform linux/amd64 to build and run.
FROM condaforge/miniforge3:24.9.2-0

COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && conda clean --all --yes

# Main env first on PATH; /opt/conda/bin stays available for Snakemake's --use-conda
ENV PATH=/opt/conda/envs/wes-demo/bin:/opt/conda/bin:$PATH \
    JAVA_HOME=/opt/conda/envs/wes-demo/lib/jvm
WORKDIR /work

CMD ["snakemake", "--cores", "4", "--use-conda"]
