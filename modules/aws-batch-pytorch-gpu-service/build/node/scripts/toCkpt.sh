#!/bin/bash

model_path=$1
ckpt_name=$(basename $model_path)
ckpt_path="${ckpt_name}.ckpt"
python3 /home/ubuntu/node/scripts/convertToCkpt.py --model_path=$model_path --checkpoint_path="/home/ubuntu/src/dreambooth/examples/dreambooth/text-inversion-model/$ckpt_path"
ls -la /home/ubuntu/src/dreambooth/examples/dreambooth/text-inversion-model
echo "/home/ubuntu/node/scripts/"
ls -la /home/ubuntu/node/scripts/