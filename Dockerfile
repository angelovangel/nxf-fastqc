FROM continuumio/miniconda:4.7.12
MAINTAINER Angel Angelov <aangeloo@gmail.com>

LABEL description="Docker image containing all requirements for the fastp-MultiQC pipeline"

COPY environment.yaml .
RUN conda env update -n root -f /environment.yaml && conda clean -a