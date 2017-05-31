# terraform config to setup a t2.micro using an AMI

provider "aws" {
  access_key = "AKIAIWNSKH3ASQMBPUYQ"
  secret_key = "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"
  aws_key_name = "kp_se_eval.pem"
  aws_key_path = "~/.ssh/"
  availability_zone = "us-east-1d"
  region     = "us-east-1"
}

resource "aws_instance" "austin-eval" {
  ami           = "ami-6edd3078"
  instance_type = "t2.micro"
}