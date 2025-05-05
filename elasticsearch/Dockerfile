FROM elasticsearch:8.17.3

RUN mkdir -p /tmp/ops_scripts
COPY *.sh /tmp/ops_scripts/
USER root
RUN chmod +x /tmp/ops_scripts/*.sh
RUN chown -R elasticsearch:elasticsearch /tmp/ops_scripts
USER elasticsearch
