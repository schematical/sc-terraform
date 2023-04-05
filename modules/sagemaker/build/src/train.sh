
# ["/opt/conda/install/bin/conda", "run", "--no-capture-output", "-n", "ldm", "/bin/bash", "-c", "/home/ubuntu/src/train.sh"]
# aws s3 cp s3://dreambooth-worker-v1-prod-us-east-1/training_data/lltest1/ /home/ubuntu/src/images  --recursive

cd /home/ubuntu/src/dreambooth

echo "!!!!!!conda init bash"
/opt/conda/install/bin/conda init bash
python /home/ubuntu/src/dreambooth/main.py \
  --base /home/ubuntu/src/dreambooth/configs/stable-diffusion/v1-finetune_unfrozen.yaml \
  -t \
  --actual_resume /home/ubuntu/src/model.ckpt \
  -n Test1 \
  --gpus '0,1,2,3,' \
  --data_root /home/ubuntu/src/images \
  --reg_data_root /home/ubuntu/src/reg_images \
  --class_word lzstlrry


