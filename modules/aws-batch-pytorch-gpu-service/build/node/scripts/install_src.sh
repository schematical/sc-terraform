cd /home/ubuntu/src
rm -rf /home/ubuntu/src/dreambooth
git clone https://github.com/ShivamShrirao/diffusers /home/ubuntu/src/dreambooth
cd /home/ubuntu/src/dreambooth/
pip3 install .
cd /home/ubuntu/src/dreambooth/examples/dreambooth
pip3 install -U -r requirements.txt
pip3 install bitsandbytes
accelerate config default
