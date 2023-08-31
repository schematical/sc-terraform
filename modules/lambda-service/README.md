# AWS Lambda MicroService
This module allows you to quickly boot up an AWS Lambda MicroService with IAM Roles and Security Groups

## How does it work?
Most of the answers you are looking for is in this video that specifically covers these modules
[![](./thumb.png)](https://youtu.be/UDkZC-SmbFM)

## How to use it:
```

data "aws_caller_identity" "current" {}
module "lambda_service" {
  service_name = "schematical-com-v1-${var.env}-www"
  source = "git::https://github.com/schematical/sc-terraform.git//modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  handler = "handler.main"

}
```


### Support:
Interested in supporting me as I maintain these free scripts? Click the link below:

<a href="https://www.buymeacoffee.com/schematical" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" />
</a>






### Need Help:

#### Jump On The Discord:
This stuff can be a bit complex. Luckily we have a small community of people that like to help.
So head on over to the [Discord](https://discord.gg/F6cErPe6VJ) and feel free to ask any questions you might have.

#### Need more help:
I do consult on this so feel free to hop on over to [Schematical.com](https://schematical.com?utm_source=github_sc-terraform-cicd) and signup for a consultation.






