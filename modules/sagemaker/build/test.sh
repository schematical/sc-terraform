aws sagemaker create-training-job --profile schematical
    --training-job-name test-$(date +"%Y-%m-%d %H:%M:%S")
    --role-arn arn:aws:iam::368590945923:role/sagemaker_test_role
    --output-data-config  { "S3OutputPath": "s3://schematical-sagemaker-test/training_output"}
    --input-data-config  { "S3OutputPath": "s3://dreambooth-worker-v1-prod-us-east-1/training_data/lltest1"}
    --resource-config {
                        "InstanceType": "ml.g4dn.2xlarge",
                        "InstanceCount": 1,
                        "VolumeSizeInGB": 32,
                        "VolumeKmsKeyId": "string",
                        "InstanceGroups": [
                          {
                            "InstanceType": "ml.g4dn.2xlarge",
                            "InstanceCount": 1,
                            "InstanceGroupName": "string"
                          }
                        ],
                        "KeepAlivePeriodInSeconds": 1
                      }
    --algorithm-specification { "TrainingImage": "368590945923.dkr.ecr.us-east-1.amazonaws.com/sagemaker-test-dev-us-east-1:dev" }



    aws sagemaker create-training-job \
    --training-job-name test \
    --algorithm-specification TrainingImage=368590945923.dkr.ecr.us-east-1.amazonaws.com/sagemaker-test-dev-us-east-1:dev,TrainingInputMode=File,EnableSageMakerMetricsTimeSeries=false \
    --role-arn arn:aws:iam::368590945923:role/sagemaker_test_role \
    --input-data-config '[{"ChannelName": "train","DataSource": {"S3DataSource": {"S3DataType": "S3Prefix","S3Uri": "s3://dreambooth-worker-v1-prod-us-east-1/training_data/lltest1","S3DataDistributionType": "FullyReplicated"}},"CompressionType": "None","RecordWrapperType": "None"}]' \
    --output-data-config S3OutputPath=s3://schematical-sagemaker-test/training_output \
    --resource-config InstanceType=ml.m4.xlarge,InstanceCount=1,VolumeSizeInGB=1,KeepAlivePeriodInSeconds=0 \
    --stopping-condition MaxRuntimeInSeconds=86400 \
    --vpc-config SecurityGroupIds=sg-0697b59d004c313dd,Subnets=subnet-093cb8fbb11da70ab,subnet-035769cd699ccd5b1 \
    --checkpoint-config S3Uri=s3://schematical-sagemaker-test/training_checkpoints
