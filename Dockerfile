FROM continuumio/miniconda:4.7.12
MAINTAINER Angel Angelov <aangeloo@gmail.com>

LABEL description="Docker image containing all requirements for the fastp-MultiQC pipeline"

COPY environment.yml .
RUN conda env update -n root -f environment.yml && conda clean -a
RUN apt-get update && apt-get install -y ksh
RUN apt-get update && apt-get install -y procps
RUN echo "See you!"