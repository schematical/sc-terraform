# sc-terraform

This repo is a few free opensource [Terraform](https://terraform.io/) scripts to help you get your infrastructure standardized on [Amazon Web Services](https://aws.amazon.com/).

## Work In Progress:
For years and years I(Matt) designed, deployed and scaled infrastructure on AWS for big clients. 
Recently I decided to release my own set of tools and scripts to help anyone that wants to learn. 
But please understand these are still a Work In Progress. I will try and let you know what is more stable. 

If you have any questions please feel free to jump on our [Discord Channel](https://discord.gg/F6cErPe6VJ) and ask.

I tend to make YouTube videos explaining how things work on my [YouTube Channel](https://www.youtube.com/@Schematical)


## Modules:
### Basic VPC:
Want to quickly boot up a secure [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) complete with secure private and public subnets to run your infrastructure in? 

Start with this module: [./modules/vpc](./modules/vpc).

### Env Template:
(Template - Not exactly a module).
Just like pushing code from `dev` to `qa` to `staging` then to `production`  you want your various environments to have similar structure. 
This allows you to define what an environment looks like from an infrastructure standpoint.
[./modules/env](./modules/env).

This should build off the VPC Module above.


### Sagemaker Inference Endpoint:
Currently,(with some tweaking) this will allow you to get your Model(either trained on sagemaker or trained somewhere else) up and running on Sagemaker's Async Inference Endpoint. 

Warning: It is NOT as cost optimised as my work with [AWSBatch on CloudFormation](https://github.com/schematical/cf-pytorch-gpu-service) but it is slightly faster.

[./modules/sagemaker](./modules/sagemaker)

### Build Pipeline:

Building manually on your local machine can lead to costly mistakes. 
AWS's BuildPipeline/CodeBuild allows us to deploy standardized CI/CD pipelines that will do the heavy lifting for us while ensuring build standards.


[./modules/buildpipeline](./modules/buildpipeline)



### Need Help:

#### Jump On The Discord:
This stuff can be a bit complex. Luckily we have a small community of people that like to help.
So head on over to the [Discord](https://discord.gg/F6cErPe6VJ) and feel free to ask any questions you might have.

#### Need more help:
I do consult on this so feel free to hop on over to [Schematical.com](https://schematical.com?utm_source=github_sc_terraform_readmee) and signup for a consultation.  


### Support:
Interested in supporting me as I maintain these free scripts? Click the link below:

<a href="https://www.buymeacoffee.com/schematical" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>


