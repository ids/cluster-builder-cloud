variable "aws_access_key" {
  type    = string
  default = env("AWS_ACCESS_KEY_ID")
}

variable "aws_secret_key" {
  type    = string
  default = env("AWS_SECRET_ACCESS_KEY")
}

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "k8s-ubuntu-cluster-node" {
  access_key    = "${var.aws_access_key}"
  ami_name      = "k8s-ubuntu-cluster-node ${local.timestamp}"
  instance_type = "t2.micro"
  region        = "ca-central-1"
  subnet_id     = "subnet-e96ee080"
  vpc_id        = "vpc-77e86e1e"
  secret_key    = "${var.aws_secret_key}"
  source_ami    = "ami-0b6937ac543fe96d7"
  ssh_username  = "ubuntu"
  associate_public_ip_address = "true"
}


build {
  sources = ["source.amazon-ebs.k8s-ubuntu-cluster-node"]

  provisioner "shell" {
    script          = "bin/ubuntu-update.sh"                    
  }
  provisioner "shell" {
    script          = "bin/ubuntu-reboot.sh"                    
    expect_disconnect = true
    pause_after  = "5s"
  }
  provisioner "shell" {
    script          = "bin/ubuntu-bootstrap.sh"                    
  }
  provisioner "shell" {
    script          = "bin/ubuntu-reboot.sh"                   
    expect_disconnect = true
    pause_after  = "5s"
  }
  provisioner "shell" {
    script          = "bin/ubuntu-k8s.sh"                   
    pause_after  = "5s"
  }

  post-processor "manifest" {
    output = "aws_manifest.json"
    strip_path = true
    custom_data = {
      my_custom_data = "example"
    }
  }

}
