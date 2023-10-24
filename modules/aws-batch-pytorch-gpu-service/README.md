https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-anywhere-updates.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/iam-role-ecsanywhere.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/manually_update_agent.html
```
export AWS_REGION=us-east-1
gpg --keyserver hkp://keys.gnupg.net:80 --recv BCE9D9A42D51784F
curl -o amazon-ecs-init.deb https://s3.$AWS_REGION.amazonaws.com/amazon-ecs-agent-$AWS_REGION/amazon-ecs-init-latest.amd64.deb
curl -o amazon-ecs-init.deb.asc https://s3.$AWS_REGION.amazonaws.com/amazon-ecs-agent-$AWS_REGION/amazon-ecs-init-latest.amd64.deb.asc
gpg --verify amazon-ecs-init.deb.asc ./amazon-ecs-init.deb
sudo dpkg -i ./amazon-ecs-init.debsudo dpkg -i ./amazon-ecs-init.deb


```

sudo
```terraform
resource "aws_iam_role" "anywhere_iam_role" {
  name = "ECSAnywhereIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}
```


```
export AWS_REGION=us-east-1
export ECS_CLUSTER=AWSBatch-chaospixel-worker-dev-us-east-1-d4f3cea7-f9f6-3c58-8e45-d852a4121e64
aws ssm create-activation --iam-role ECSAnywhereIAMRole | tee ssm-activation.json
curl --proto "https" -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent.s3.amazonaws.com/ecs-anywhere-install-latest.sh"
sudo bash /tmp/ecs-anywhere-install.sh \
    --region $AWS_REGION \
    --cluster $ECS_CLUSTER \
    --activation-id 91a0148b-8059-49f8-8f35-9bb84eb2c7ac \
    --activation-code Sz6HHWZ10nCdBGnEqg3j \
    --enable-gpu

echo "ECS_CLUSTER=AWSBatch-chaospixel-worker-dev-us-east-1-d4f3cea7-f9f6-3c58-8e45-d852a4121e64" >> /etc/ecs/ecs.config
```
https://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html


```terraform
#deb cdrom:[Ubuntu 22.10 _Kinetic Kudu_ - Release amd64 (20221020)]/ kinetic main restricted

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://us.archive.ubuntu.com/ubuntu/ kinetic main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://us.archive.ubuntu.com/ubuntu/ kinetic-updates main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb  http://us.archive.ubuntu.com/ubuntu/ kinetic universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic universe
deb http://us.archive.ubuntu.com/ubuntu/ kinetic-updates universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu 
## team, and may not be under a free licence. Please satisfy yourself as to 
## your rights to use the software. Also, please note that software in 
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://us.archive.ubuntu.com/ubuntu/ kinetic multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic multiverse
deb http://us.archive.ubuntu.com/ubuntu/ kinetic-updates multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://us.archive.ubuntu.com/ubuntu/ kinetic-backports main restricted universe multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ kinetic-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu kinetic-security main restricted
# deb-src http://security.ubuntu.com/ubuntu kinetic-security main restricted
deb http://security.ubuntu.com/ubuntu kinetic-security universe
# deb-src http://security.ubuntu.com/ubuntu kinetic-security universe
deb http://security.ubuntu.com/ubuntu kinetic-security multiverse
# deb-src http://security.ubuntu.com/ubuntu kinetic-security multiverse

# This system was installed using small removable media
# (e.g. netinst, live or single CD). The matching "deb cdrom"
# entries were disabled at the end of the installation process.
# For information about how to configure apt package sources,
# see the sources.list(5) manual.



```