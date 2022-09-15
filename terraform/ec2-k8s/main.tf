terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_vpc" "ec2-k8s-vpc" {
  cidr_block = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "ec2-k8s-gw" {
  vpc_id = aws_vpc.ec2-k8s-vpc.id

  tags = {
    Name = var.internet_gw_name
  }
}

resource "aws_default_route_table" "ec2-k8s-route-table" {
  default_route_table_id = aws_vpc.ec2-k8s-vpc.default_route_table_id     

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ec2-k8s-gw.id
  }


  tags = {
    Name = var.ec2_k8s_route_table_name
  }
}

resource "aws_subnet" "ec2-k8s-public-subnet" {
  vpc_id     = aws_vpc.ec2-k8s-vpc.id
  cidr_block = var.ec2_k8s_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = var.ec2_k8s_subnet_name
  }
}

resource "aws_network_acl" "ec2-k8s-nacl" {
  vpc_id = aws_vpc.ec2-k8s-vpc.id
  subnet_ids = ["${aws_subnet.ec2-k8s-public-subnet.id}"]

  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = var.ec2_k8s_nacl_name
  }
}


resource "aws_security_group" "allow_creator_admin" {
  name        = var.ec2_k8s_sg_allow_creator_name
  description = "Allow SSH from creator IP"
  vpc_id      = aws_vpc.ec2-k8s-vpc.id

  ingress {
    description      = "SSH from creator IP for EC2 K8s"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description      = "K8s control plane for creator"
    from_port        = 0
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.response_body)}/32"]
  }

  tags = {
    Name = var.ec2_k8s_sg_allow_creator_name
  }
}

resource "aws_security_group" "k8s_control_plane" {
  name        = var.ec2_k8s_sg_k8s_control_plane_name
  description = "Allow K8s ports"
  vpc_id      = aws_vpc.ec2-k8s-vpc.id

  ingress {
    description      = "K8s control plane for subnet"
    from_port        = 0
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["${var.ec2_k8s_subnet_cidr_block}"]
  }

  tags = {
    Name = var.ec2_k8s_sg_k8s_control_plane_name
  }
}

resource "aws_security_group" "allow_outbound" {
  name        = var.ec2_k8s_sg_allow_outbound_name
  description = "Allow Outbound traffic from EC2 instance nodes"
  vpc_id      = aws_vpc.ec2-k8s-vpc.id

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.ec2_k8s_sg_allow_outbound_name
  }
}


resource "aws_instance" "k8s-master" {
  ami           = var.node_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.ec2-k8s-public-subnet.id 

  tags = {
    Name = var.ec2_k8s_master_name
  }

  vpc_security_group_ids = ["${aws_security_group.allow_creator_admin.id}", 
                            "${aws_security_group.k8s_control_plane.id}", 
                            "${aws_security_group.allow_outbound.id}"]
  key_name = var.keypair_name
}

resource "aws_instance" "k8s-worker" {
  ami           = var.node_ami
  instance_type = "t3.small"
  subnet_id     = aws_subnet.ec2-k8s-public-subnet.id 
  count = 1

  tags = {
    Name = var.ec2_k8s_worker_name
  }
  vpc_security_group_ids = ["${aws_security_group.allow_creator_admin.id}", 
                        "${aws_security_group.k8s_control_plane.id}", 
                        "${aws_security_group.allow_outbound.id}"]
  key_name = var.keypair_name
}

output "k8s_master_lines" {
  value = {
    for k, v in aws_instance.k8s-master.* : k => "${v.public_dns}  ansible_host=${v.public_ip}"
  }
}
output "k8s_worker_lines" {
  value = {
    for k, v in aws_instance.k8s-worker.* : k => "${v.public_dns}  ansible_host=${v.public_ip}"
  }
}

output "ssh_to_master" {
  value = "ssh ubuntu@${aws_instance.k8s-master.public_dns}"
}