cd /home/ubuntu/src
git clone https://github.com/ShivamShrirao/diffusers /home/ubuntu/src/dreambooth
cd /home/ubuntu/src/dreambooth
/opt/conda/install/bin/conda env create -f ./environment.yaml --prefix /opt/conda/install/envs/ldm -v
/opt/conda/install/bin/conda init bash
/opt/conda/install/bin/conda install pip -y
pip install -U -r requirements.txt
accelerate config default
