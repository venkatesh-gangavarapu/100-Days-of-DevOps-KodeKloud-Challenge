provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "datacenter_priv_vpc" {
  cidr_block = var.KKE_VPC_CIDR
  tags = { Name = "datacenter-priv-vpc" }
}

resource "aws_subnet" "datacenter_priv_subnet" {
  vpc_id                  = aws_vpc.datacenter_priv_vpc.id
  cidr_block              = var.KKE_SUBNET_CIDR
  map_public_ip_on_launch = false
  tags = { Name = "datacenter-priv-subnet" }
}

resource "aws_security_group" "datacenter_priv_sg" {
  name   = "datacenter-priv-sg"
  vpc_id = aws_vpc.datacenter_priv_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.KKE_VPC_CIDR]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "datacenter_priv_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.datacenter_priv_subnet.id
  vpc_security_group_ids = [aws_security_group.datacenter_priv_sg.id]
  tags = { Name = "datacenter-priv-ec2" }
}
