#######################AZA67##################
A brutish recreation of the 3 tier architecture shown here (03-basics):

https://youtu.be/7xngnjfIlK4?si=HjZzJxiQVgjs-Nlx
################################################
#__         __# 
#  \  ___  /  #
#   \|-_-|/   #
#    |_^_|    #
##########################################
source code can be found and pulled here:

https://github.com/sidpalas/devops-directive-terraform-course.git
##########################################

#########################################
HOW MY APPROACH DIFFERS FROM '03-basics':
#########################################

- I did not have a default vpc on my aws account;
    + so I had to define the resources in main.tf

- Source code has a pre-provisioned back-end (s3 and DB)
    + I did not set this up so it is also defined in main.tf

- Source code had several outdated resource descriptions and configurations that I needed to update
###

#######################
STEPS TAKEN IN Main.tf:
#######################

1: backend + provider config (remote backend not applied in this folder)
2: ec2 instances
3: S3 bucket
4: VPC config
    4.1: subnet config
5: security groups + rules
6: application load blancer 
    6.1: ALB target group + attatchment
7: Route 53 zone + record
8: RDS instance     
###

#################################################
        -FOR FUTURE USE (REMOTE-BACKEND)-
#################################################

Setting up a remote backend with aws

requirements:
- S3 bucket (used for storage)
- DynamoDB table (used for encyrption)
    -*Also used as a version control system

STEP 1: 
- configure env with no backend to setup s3 and dynamodb

###main.tf###

##Defaults to local backend##

#terraform {
#    required_providers {
#        aws = {
#            source = "hashicorp/aws"
#            version = "~> 3.0"
#        }
#    }
#}

#provider "aws" {
#    region = "us-east-1"
#}

##Define versioned and encrypted s3 bucket##

#resource "aws_s3_bucket" "terraform_state" {
#    bucket      = "devops directive-tf-state"
#    force_destroy = true
#    versioning {
#        enabled = true
#    }
#
#    server_side_encyrption_configuration {
#        rule {
    
#    apply_server_side_encryption_by_default {
#                see_algortithm = "AE256"
#            }
#        }
#    }
#}

##define DynamboDB table##

#resource "aws_dynamodb_table" "terraform_locks" {
#  name          = "terraform-state-locking"
#  billing_mode  = "PAY_PER_REQUEST"
#  hash_key      = "LockID"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}


STEP 2: $terraform apply 
- provisions backend for future use

STEP 3: edit main.tf to specify backend from 'Step 1'
###main.tf###
##define backend and config##
#
terraform {
  backend "s3" {
    bucket          = "devops-directive-tf-state"
    key             = "tf-infra/terraform-tfstate"
    region          = "us-east-1"
    dynamodb_table  = "terraform-state-locking"
    encrypt         = true      
  }

  required_providers {
    aws = {
        source = "hasicorp/aws"
        version = "~> 3.0"
    }
  }
}
#
STEP 4: reinitialize directory
- terraform then goes back and changes backend for the project