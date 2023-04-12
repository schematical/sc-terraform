## Sagemaker Async Inference Endpoint:
(Work in progress). 
This Terraform module was designed to quickly get a model up and running on AWS Sagemaker for production use.


### Notes on the Example:
The example model / ml framework is Dreambooth running on Pytorch, but you should be able to switch it up to any python ML framework.

### Related Scripts:
This builds off the rest of the [sc-terraform](https://github.com/schematical/sc-terraform) repo.


## TODO:
1) Lots of polish
2) Remove the NodeJS. Since the Docker image already has Python we should just use that. It was just faster as I was prototyping to throw NodeJS and express in there.


```
aws sagemaker --profile schematical describe-training-job --training-job-name test

{
    "TrainingJobName": "test",
    "TrainingJobArn": "arn:aws:sagemaker:us-east-1:368590945923:training-job/test",
    "TrainingJobStatus": "InProgress",
    "SecondaryStatus": "Starting",
    "AlgorithmSpecification": {
        "TrainingImage": "368590945923.dkr.ecr.us-east-1.amazonaws.com/sagemaker-test-dev-us-east-1:dev",
        "TrainingInputMode": "File",
        "EnableSageMakerMetricsTimeSeries": false
    },
    "RoleArn": "arn:aws:iam::368590945923:role/service-role/SageMaker-sagemaker-studio",
    "InputDataConfig": [
        {
            "ChannelName": "train",
            "DataSource": {
                "S3DataSource": {
                    "S3DataType": "S3Prefix",
                    "S3Uri": "s3://dreambooth-worker-v1-prod-us-east-1/training_data/lltest1",
                    "S3DataDistributionType": "FullyReplicated"
                }
            },
            "CompressionType": "None",
            "RecordWrapperType": "None"
        }
    ],
    "OutputDataConfig": {
        "KmsKeyId": "",
        "S3OutputPath": "s3://schematical-sagemaker-test/training_output"
    },
    "ResourceConfig": {
        "InstanceType": "ml.m4.xlarge",
        "InstanceCount": 1,
        "VolumeSizeInGB": 1,
        "KeepAlivePeriodInSeconds": 0
    },
    "VpcConfig": {
        "SecurityGroupIds": [
            "sg-0697b59d004c313dd"
        ],
        "Subnets": [
            "subnet-093cb8fbb11da70ab",
            "subnet-035769cd699ccd5b1"
        ]
    },
    "StoppingCondition": {
        "MaxRuntimeInSeconds": 86400
    },
    "CreationTime": "2023-04-05T10:29:57.352000-05:00",
    "LastModifiedTime": "2023-04-05T10:30:36.104000-05:00",
    "SecondaryStatusTransitions": [
        {
            "Status": "Starting",
            "StartTime": "2023-04-05T10:29:57.352000-05:00",
            "StatusMessage": "Preparing the instances for training"
        }
    ],
    "EnableNetworkIsolation": false,
    "EnableInterContainerTrafficEncryption": false,
    "EnableManagedSpotTraining": false,
    "CheckpointConfig": {
        "S3Uri": "s3://schematical-sagemaker-test/training_checkpoints"
    },
    "ProfilingStatus": "Disabled"
}

```