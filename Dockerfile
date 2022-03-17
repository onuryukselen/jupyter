# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM dolphinnext/jupyter-base-notebook:1.0

LABEL maintainer="Onur Yukselen <onur.yukselen@umassmed.edu>"

USER root

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy curl && \
    curl -sSL https://get.docker.com/ | sh

USER ${NB_UID}

# R packages including IRKernel which gets installed globally.
# r-e1071: dependency of the caret R package
RUN mamba install --quiet --yes \
    'r-base' \
    'r-caret' \
    'r-crayon' \
    'r-devtools' \
    'r-e1071' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    'r-nycflights13' \
    'r-randomforest' \
    'r-rcurl' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-tidyverse' \
    'unixodbc' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# `r-tidymodels` is not easy to install under arm
# hadolint ignore=SC2039
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" == "x86_64" ]; then \
        mamba install --quiet --yes \
            'r-tidymodels' && \
            mamba clean --all -f -y && \
            fix-permissions "${CONDA_DIR}" && \
            fix-permissions "/home/${NB_USER}"; \
    fi;

RUN conda update conda
RUN pip install jupyter-server-proxy
RUN jupyter serverextension enable --sys-prefix jupyter_server_proxy
USER root
RUN NPROCS=`awk '/^processor/ {s+=1}; END{print s}' /proc/cpuinfo`
#COPY install_packages.R /
#RUN Rscript /install_packages.R

#####################
### R packages ######
#####################

RUN R --slave -e "install.packages(c('ggplot2', 'plyr', 'dplyr', 'data.table', 'reshape', 'RColorBrewer', 'reshape2', 'circlize', 'BiocManager', 'ggplot2', 'knitr', 'xtable', 'pheatmap', 'RColorBrewer', 'rmarkdown'), dependencies = TRUE, repos='https://cran.rstudio.com', Ncpus=${NPROCS})"
RUN R --slave -e "BiocManager::install(c('MAGeCKFlute', 'debrowser', 'iSEE', 'scRNAseq', 'scater'))"

RUN python3 -m pip install papermill 
RUN apt-get install -y vim
RUN chmod +x /usr/local/bin/start.sh
COPY startup /
CMD ["/startup"]
