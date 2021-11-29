FROM continuumio/miniconda3:4.10.3
LABEL author="Angel Angelov <aangeloo@gmail.com>"
LABEL description="Docker image containing all requirements for the nxf-fastqc pipeline"

COPY environment.yml .
RUN conda env update -n root -f environment.yml && conda clean -afy && pip install git+https://github.com/ewels/MultiQC.git
RUN apt-get update && apt-get install -y ksh procps libxt-dev
# libxt-dev is required to solve the segfault error caused by cairoVersion() in R

# setup faster and fastkmers for linux
RUN wget -P bin https://github.com/angelovangel/faster/releases/download/v0.1.4/x86_64_linux_faster && \
mv bin/x86_64_linux_faster bin/faster && \
chmod 755 bin/faster

RUN wget -P bin https://github.com/angelovangel/fastkmers/releases/download/v0.1.0/fastkmers && \
chmod 755 bin/fastkmers


RUN R -e "install.packages('sparkline', repos='http://cran.rstudio.com/')"