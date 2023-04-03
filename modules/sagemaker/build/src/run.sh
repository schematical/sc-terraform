cd /home/ubuntu/src/dreambooth

echo "/opt----------------------\n"
ls -la /opt
echo "/opt/ml----------------------\n"
ls -la /opt/ml
echo "----------------------\n"
ls -la /opt/ml/model
echo "/opt/ml/model----------------------\n"
# echo 'conda run -n ldm /bin/bash -c conda activate ldm'
# conda run -n ldm /bin/bash -c conda activate ldm
echo "!!!!!!conda init bash"
/opt/conda/install/bin/conda init bash


# echo "!!!!! cat /root/.bashrc"
# cat /root/.bashrc

# echo "!!!!! conda activate ldm"
# conda activate ldm
echo "!!!!Sending it. Dir: $1 Prompt: $2 Seed: $3"
python /home/ubuntu/src/dreambooth/scripts/stable_txt2img.py --outdir "/home/ubuntu/src/outputs/$2" --ddim_eta 0.0 --n_samples 1 --n_iter 4 --scale 10.0 --ddim_steps 50 --seed $4 --ckpt /opt/ml/model/model.pth --prompt "$3"

echo "!!!!Pushing to S3"
aws s3 cp /home/ubuntu/src/outputs/$1 s3://$1/$2 --recursive

echo "!!!!Cleaning Up"
rm -rf /home/ubuntu/src/outputs/$1

echo "!!!!!!DONE"
#["conda", "run", "-n", "ldm",  "/bin/bash",  "-c",  "sh", "/home/ubuntu/node/test.sh"]

