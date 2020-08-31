terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/dns-zones/jeremychase-io"
    region = "us-east-1"
  }

  required_version = "~> 0.12.24" # BUG(medium) Update to terraform 0.13

  required_providers {
    aws = "3.2.0"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

###
#
# NOTE:
#
# Recreation results in new name servers which need to be updated with the registrar.
# Related to https://github.com/terraform-providers/terraform-provider-aws/issues/88
#
resource "aws_route53_zone" "self" {
  name = var.zone_name
}

