# FROM nvidia/cuda:11.3.1-runtime-ubuntu20.04
FROM 368590945923.dkr.ecr.us-east-1.amazonaws.com/schematicabot-worker:base
ENV CONDA_DIR /opt/conda
ARG DEBIAN_FRONTEND=noninteractive


COPY ./src /home/ubuntu/src
COPY ./package-lock.json /home/ubuntu
COPY ./package.json /home/ubuntu

RUN apt update && \
    apt install --no-install-recommends -y curl unzip build-essential gcc git wget libcudnn8 nodejs npm  && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install  && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda/install \ && \
    export PATH=/opt/conda/install/bin:$PATH && \
    echo "export PATH=/opt/conda/install/bin:$PATH" >> ~/.bashrc   && \
    cd /home/ubuntu && \
    npm ci && \
    git clone https://github.com/XavierXiao/Dreambooth-Stable-Diffusion /home/ubuntu/src/dreambooth  && \
    cd /home/ubuntu/src/dreambooth  && \
    ls -la  && \
    /opt/conda/install/bin/conda env create -f ./environment.yaml --prefix /opt/conda/install/envs/ldm -v  && \
    /opt/conda/install/bin/conda init bash  && \
    /opt/conda/install/bin/conda install pip -y && \
    cp  /home/ubuntu/src/serve  /home/ubuntu/serve && \
    chmod 755 /home/ubuntu/serve && \
    chmod 755 /home/ubuntu/src/run.sh

WORKDIR /home/ubuntu
ENV PATH="/home/ubuntu:${PATH}"
ENV  PATH /opt/conda/bin:$PATH
ENTRYPOINT ["sh", "/home/ubuntu/serve"]


CMD ["node", "/home/ubuntu/src/run.js", "test", "'a city skyline'", "1"]
