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

# Configure vpc to match architecture.png
resource "aws_vpc" "tf-webapp_vpc" {
    cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "pub_sub1" {
  vpc_id     = aws_vpc.tf-webapp_vpc.id
  cidr_block = "10.0.0.0/28"
}

resource "aws_subnet" "priv_sub1" {
  vpc_id     = aws_vpc.tf-webapp_vpc.id
  cidr_block = "10.0.0.16/28"
}

#configure security group for ec2s
resource "aws_security_group" "instances" {
    name = "instance-security-group"
}
#set inbound rules for security group
resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress" #specifies an inbound rulw
    security_group_id = aws_security_group.instances.id

    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #traffic allowed from anywhere
}

#provision a load balancer and configure to allow traffic on port 80
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.load_balancer.arn

    port = 80 #listening on port 80

    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

#configure a target group for the load balancer (point to ec2 instances)
resource "aws_lb_target_group" "instances" {
    name = "example-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = aws_vpc.tf-webapp_vpc.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

#attach both ec2 instances to the target group specified in above
resource "aws_lb_target_group_attachment" "instance_1" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance_1.id
    port = 8080
}
resource "aws_lb_target_group_attachment" "instance_2" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance_2.id
    port = 8080
}

#setup listener rules for the load balancer
resource "aws_lb_listener_rule" "instances" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = "aws_lb_target_group.instances.arn"
    }
}

#Configure different security groups for the load balancer
resource "aws_security_group" "alb" {
    name = "alb-security-group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id

    from_port = 0
    to_port = 0
    protocol = "-1" #(NO outbound traffic configured)
    cidr_blocks = ["0.0.0.0/0"]
}

#define subnet and security group for lb
resource "aws_lb" "load_balancer" {
    name = "web-app-lb"
    load_balancer_type = "application"
    subnets = aws_subnet_ids.pub_sub1.ids
    security_groups = [aws_security_group.alb.id]
}

#configure route 53 with DNS for public access through site using a domain
resource "aws_route53_zone" "primary" {
    name = "devopsdeployed.com" #(a domain that yt creator owns(provisioned as a zone because each zone can have specific records associated with it))
}

resource "aws_route53_record" "root" { #(traffic coming into devopdeployed.com will be forwaded to specified LB and then one of the ec2 instances)
    zone_id = aws_route53_zone.primary.zone_id
    name = "devopsdeployed.com"
    type = "A" 

    alias {
        name = aws_lb.load_balancer.dns_name
        zone_id = aws_lb.load_balancer.zone_id
        evaluate_target_health = true
    }
}

#configure ec2 instances
resource "aws_instance" "instance_1" {
  ami             = "ami-0c7217cdde317cfec" #ubuntu 22.04 (us-east-1)
  instance_type   = "t2.micro" 
  security_groups = [aws.security_group.instance] #allows inbound traffic from the internet
  user_data       = <<-EOF
             #!/bin/bash
             echo "hello, world 1" > index.html
             python3 -m http.server 8080 &
             EOF
}

resource "aws_instance" "instance_2" {
    ami             = "ami-0c7217cdde317cfec"
    instance_type   = "t2.micro"
    security_groups = [aws.security_group.instance.name]
    user_data       = <<-EOF
                #!/bin/bash
                echo "hello world 2" > index.html
                python3 -m http.server 8080 &
                EOF
}

#configure s3 bucket and encryption
resource "aws_s3_bucket" "bucket" {
  bucket = "devops-directive-web-app-data"
  force_destroy = true
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
  }
}

#Database configuration 
resource "aws_db_instance" "db_instance" {
    allocated_storage = 20
    storage_type = "standard"
    engine = "postgres"
    engine_version = "12.5"
    instance_class = "db.t2.micro"
    name = "mydb"
    username = "foo"
    password = "foobarbaz"
    skip_final_snapshot = true
}
