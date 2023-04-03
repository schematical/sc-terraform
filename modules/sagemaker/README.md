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


