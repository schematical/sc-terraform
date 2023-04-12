#!/bin/sh

echo "The script was called with $# arguments."
echo "The arguments are:  $1, $2, $3, $4, $5"


echo "ls /opt/ml/"
ls -la /opt/ml/
echo "cat /opt/ml/input/config/inputdataconfig.json"
cat /opt/ml/input/config/inputdataconfig.json
echo "ls /opt/ml/input/data/train"
ls -la /opt/ml/input/data/train

echo "ls -la /opt/ml/checkpoints"
ls -la /opt/ml/checkpoints

echo "------------\n"
cd /home/ubuntu/src/dreambooth

echo "!!!!!!conda init bash"
/opt/conda/install/bin/conda init bash
python /home/ubuntu/src/dreambooth/main.py \
  --base /home/ubuntu/src/dreambooth/configs/stable-diffusion/v1-finetune_unfrozen.yaml \
  -t \
  --actual_resume  /opt/ml/checkpoints/Public-Prompts-Pixel-Model.ckpt \
  -n Test1 \
  --gpus '0,' \
  --data_root /opt/ml/input/data/train \
  --reg_data_root /opt/ml/input/data/reg \
  --class_word lzstlrry \
  --gradient_accumulation_steps=1 --gradient_checkpointing --use_8bit_adam

