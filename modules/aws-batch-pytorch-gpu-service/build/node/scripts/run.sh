cd /home/ubuntu/src/dreambooth/examples/dreambooth

#echo "!!!!!!! ls -la /home/ubuntu/src/dreambooth/images/shay"
#ls -la /home/ubuntu/src/dreambooth/images/shay

cat /home/ubuntu/concepts_list.json

echo "!!!!Sending it."
accelerate launch \
  --mixed_precision="fp16" \
  /home/ubuntu/src/dreambooth/examples/dreambooth/train_dreambooth.py \
  --pretrained_model_name_or_path=runwayml/stable-diffusion-v1-5 \
  --concepts_list="/home/ubuntu/concepts_list.json" \
  --resolution 512 \
  --gradient_checkpointing \
  --use_8bit_adam \
  --train_batch_size 1 \
  --sample_batch_size=1  \
  --gradient_accumulation_steps=1 \
  --gradient_checkpointing \
  --num_train_epochs 50

# echo "!!!!Pushing to S3"
# aws s3 cp /home/ubuntu/src/dreambooth/examples/dreambooth/text-inversion-model/$1 s3://$S3_BUCKET/$1 --recursive

# echo "!!!!Cleaning Up"
# rm -rf /home/ubuntu/src/dreambooth/examples/dreambooth/text-inversion-model/$1

echo "!!!!!!DONE"
#["conda", "run", "-n", "ldm",  "/bin/bash",  "-c",  "sh", "/home/ubuntu/node/test.sh"]

