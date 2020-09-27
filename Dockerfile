FROM continuumio/miniconda3:4.8.2
LABEL author="Angel Angelov <aangeloo@gmail.com>"
LABEL description="Docker image containing all requirements for the nxf-fastqc pipeline"

COPY environment.yml .
RUN conda env update -n root -f environment.yml && conda clean -afy && pip install git+https://github.com/ewels/MultiQC.git
RUN apt-get update && apt-get install -y ksh procps libxt-dev
# libxt-dev is required to solve the segfault error caused by cairoVersion() in R
RUN R -e "install.packages('sparkline', repos='http://cran.rstudio.com/')"