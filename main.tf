terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region = "eu-west-3"
  public_key = file("~/.ssh/id_rsa.pub")
}

provider "aws" {
  region = local.region
}

resource "aws_key_pair" "key_pair" {
  key_name   = "hetic-dspec-key"
  public_key = local.public_key
}

resource "aws_emr_cluster" "cluster" {
  name          = "hetic-dspec-emr-cluster"
  release_label = "emr-7.0.0"
  applications  = ["Spark"]

  ec2_attributes {
    subnet_id                         = aws_subnet.main.id
    emr_managed_master_security_group = aws_security_group.allow_access.id
    emr_managed_slave_security_group  = aws_security_group.allow_access.id
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
    key_name                          = aws_key_pair.key_pair.key_name
  }

  master_instance_group {
    instance_type = "m5.xlarge"
  }

  core_instance_group {
    instance_count = 1
    instance_type  = "m5.xlarge"
  }

  configurations_json = <<EOF
  [
    {
      "Classification": "container-executor",
      "Configurations": [
        {
          "Classification": "docker",
          "Properties": {
            "docker.privileged-containers.registries": "local,centos,${local.account_id}.dkr.ecr.${local.region}.amazonaws.com",
            "docker.trusted.registries": "local,centos,${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
          }
        }
      ],
      "Properties": {}
    }
  ]
EOF

  service_role = aws_iam_role.iam_emr_service_role.arn
}

resource "aws_ecr_repository" "repository" {
  name                 = "hetic-dspec-ecr-repository"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
