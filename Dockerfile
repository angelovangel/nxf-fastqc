FROM continuumio/miniconda:4.7.12
LABEL author="Angel Angelov <aangeloo@gmail.com>"
LABEL description="Docker image containing all requirements for the nextflow-fastp pipeline"

COPY environment.yml .
RUN conda env update -n root -f environment.yml && conda clean -a
RUN apt-get update && apt-get install -y ksh procps libxt-dev
# libxt-dev is required to solve the seqfault error caused by cairoVersion() in R
RUN R -e "install.packages('sparkline', repos='http://cran.rstudio.com/')"