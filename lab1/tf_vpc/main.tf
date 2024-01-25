terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/24"
}

# create 4 subnets (2 public, 2 private)
resource "aws_subnet" "pub-sub1" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.0.0/28"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "pub-sub2" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.0.16/28"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "pri-sub1" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.0.128/28"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "pri-sub2" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.0.144/28"
  availability_zone = "us-east-1b"
}

#not sure why I added this but just in case
resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.tf_vpc.id 
}

