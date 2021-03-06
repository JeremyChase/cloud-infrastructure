terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/aws-bastion"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.14.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "bastion" {
    description = "Allow ssh"
    egress      = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = 0
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "-1"
            security_groups  = []
            self             = false
            to_port          = 0
        },
    ]
    ingress     = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = -1
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "icmp"
            security_groups  = []
            self             = false
            to_port          = -1
        },
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = 22
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 22
        },
    ]
    name        = "bastion"
    tags        = {}
    vpc_id      = aws_default_vpc.default.id

    timeouts {}
}

resource "aws_instance" "graviton" {
  ami           = "ami-0c582118883b46f4f" # us-east-1
  instance_type = "t4g.micro"
  key_name = "jchase-jeremychase-us-east-1"

  security_groups = [aws_security_group.bastion.name]

  credit_specification {
    cpu_credits = "unlimited"
  }
}

resource "aws_eip" "graviton" {
  instance = aws_instance.graviton.id
  vpc      = true
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "eip_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "us-east-1.aws.${var.zone_name}."
  records = [
    aws_eip.graviton.public_dns,
  ]
  ttl  = 300
  type = "CNAME"
}

resource "aws_route53_record" "short_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "aws.${var.zone_name}."
  records = [
    aws_route53_record.eip_cname.name,
  ]
  ttl  = 300
  type = "CNAME"
}
