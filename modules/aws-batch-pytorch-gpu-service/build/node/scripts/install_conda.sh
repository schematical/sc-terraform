apt install --no-install-recommends -y build-essential gcc wget git curl # libcudnn8
wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
/bin/bash ~/miniconda.sh -b -p /opt/conda/install \ && \
export PATH=/opt/conda/install/bin:$PATH
