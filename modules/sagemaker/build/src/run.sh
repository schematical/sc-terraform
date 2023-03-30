cd /home/ubuntu/src/dreambooth
# echo 'conda run -n ldm /bin/bash -c conda activate ldm'
# conda run -n ldm /bin/bash -c conda activate ldm
echo "!!!!!!conda init bash"
/opt/conda/install/bin/conda init bash


# echo "!!!!! cat /root/.bashrc"
# cat /root/.bashrc

# echo "!!!!! conda activate ldm"
# conda activate ldm
echo "!!!!Sending it. Dir: $1 Prompt: $2 Seed: $3"
python /home/ubuntu/src/dreambooth/scripts/stable_txt2img.py --outdir "/home/ubuntu/src/outputs/$1" --ddim_eta 0.0 --n_samples 1 --n_iter 4 --scale 10.0 --ddim_steps 50 --seed $3 --ckpt /home/ubuntu/src/model.ckpt --prompt "$2"

echo "!!!!Pushing to S3"
aws s3 cp /home/ubuntu/src/outputs/$1 s3://$S3_BUCKET/$1 --recursive

echo "!!!!Cleaning Up"
rm -rf /home/ubuntu/src/outputs/$1

echo "!!!!!!DONE"
#["conda", "run", "-n", "ldm",  "/bin/bash",  "-c",  "sh", "/home/ubuntu/node/test.sh"]

