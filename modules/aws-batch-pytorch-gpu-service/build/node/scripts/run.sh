
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
  --num_train_epochs $1
  # --output_dir


