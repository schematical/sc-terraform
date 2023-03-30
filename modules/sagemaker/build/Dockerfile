FROM nvidia/cuda:11.3.1-runtime-ubuntu20.04
# FROM 368590945923.dkr.ecr.us-east-1.amazonaws.com/schematicabot-worker:base
ENV CONDA_DIR /opt/conda
ARG DEBIAN_FRONTEND=noninteractive


COPY ./src /home/ubuntu/src
RUN apt update && \
    apt install --no-install-recommends -y curl unzip build-essential gcc git wget libcudnn8 nodejs && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install  && \
    export PATH=/opt/conda/install/bin:$PATH &&\
    echo "export PATH=/opt/conda/install/bin:$PATH" >> ~/.bashrc

RUN git clone https://github.com/XavierXiao/Dreambooth-Stable-Diffusion /home/ubuntu/src/dreambooth

ENV  PATH /opt/conda/bin:$PATH

VOLUME ["/opt/conda"]
VOLUME ["/home/ubuntu/src"]
VOLUME ["/home/ubuntu/.conda"]
VOLUME ["/root/.cache"]
VOLUME ["/home/ubuntu/.cache"]

CMD ["node", "/home/ubuntu/node/run.js", "test", "'a city skyline'", "1"]
