cd /home/ubuntu/src/dreambooth
# echo 'conda run -n ldm /bin/bash -c conda activate ldm'
# conda run -n ldm /bin/bash -c conda activate ldm
echo "!!!!!!conda init bash"
/opt/conda/install/bin/conda init bash


# echo "!!!!! cat /root/.bashrc"
# cat /root/.bashrc

# echo "!!!!! conda activate ldm"
# conda activate ldm

echo $2 >> /home/ubuntu/concepts_list.json
cat /home/ubuntu/concepts_list.json

echo "!!!!Sending it. Dir: $1 Prompt: $2 Seed: $3"
accelerate launch \
  --mixed_precision="fp16" \
  train_dreambooth.py \
  --pretrained_model_name_or_path=runwayml/stable-diffusion-v1-5 \
  --instance_data_dir ./images \
  --concepts_list="/home/ubuntu/concepts_list.json" \
  --resolution 512 \
  --gradient_checkpointing \
  --use_8bit_adam \
  --train_batch_size 1 \
  --sample_batch_size=1  \
  --gradient_accumulation_steps=1 \
  --gradient_checkpointing \
  --num_train_epochs 50

echo "!!!!Pushing to S3"
aws s3 cp /home/ubuntu/src/outputs/$1 s3://$S3_BUCKET/$1 --recursive

echo "!!!!Cleaning Up"
rm -rf /home/ubuntu/src/outputs/$1

echo "!!!!!!DONE"
#["conda", "run", "-n", "ldm",  "/bin/bash",  "-c",  "sh", "/home/ubuntu/node/test.sh"]

