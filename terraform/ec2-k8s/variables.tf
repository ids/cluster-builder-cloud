variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "keypair_name" {
  description = "Name of keypair to use for SSH"
  type        = string
  default     = "AWSCanada2022"
}

variable "node_ami" {
  description = "Node AMI to use for all K8s Ec2 instance nodes"
  type        = string
  default     = "ami-09d8c574b551fd481"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "ec2-k8s-vpc"
}

variable "internet_gw_name" {
  description = "Internet GW name"
  type        = string
  default     = "ec2-k8s-gw"
}

variable "ec2_k8s_route_table_name" {
  description = "K8s VPC route table name"
  type        = string
  default     = "ec2-k8s-route-table"
}

variable "ec2_k8s_subnet_name" {
  description = "K8s Subnet name"
  type        = string
  default     = "ec2-k8s-subnet"
}

variable "ec2_k8s_subnet_cidr_block" {
  description = "K8s CIDR block"
  type        = string
  default     = "10.10.0.0/24"
}

variable "ec2_k8s_nacl_name" {
  description = "K8s NACL name"
  type        = string
  default     = "ec2-k8s-nacl"
}

variable "ec2_k8s_sg_allow_creator_name" {
  description = "K8s sg allow creator SSH name"
  type        = string
  default     = "ec2-k8s-creator-ssh"
}

variable "ec2_k8s_sg_k8s_control_plane_name" {
  description = "K8s sg name"
  type        = string
  default     = "ec2-k8s-control"
}

variable "ec2_k8s_sg_allow_outbound_name" {
  description = "K8s sg allow node outbound"
  type        = string
  default     = "ec2-k8s-allow-outbound"
}

variable "ec2_k8s_master_name" {
  description = "K8s master name"
  type        = string
  default     = "k8s-master"
}

variable "ec2_k8s_worker_name" {
  description = "K8s worker name"
  type        = string
  default     = "k8s-node"
}

