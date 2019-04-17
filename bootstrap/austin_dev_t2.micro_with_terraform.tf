# terraform config to setup a t2.micro using an AMI
#
# access_key is ONLY CAP LETTERS
# secret_key is twice as many characters  

provider "aws" {
  access_key 		= "AKIMG___fake_key___HJUYQ"
  secret_key 		= "hMj3s___fake_secret_is_twice_as_many_chars___5xFsM"
  aws_key_name 		= "key_austin_dev.pem"
  aws_key_path 		= "~/.ssh/"
  availability_zone = "us-east-1d"
  region     		= "us-east-1"
}

resource "aws_instance" "austin-dev" {
  ami           = "ami-6edd3077"
  instance_type = "t2.micro"
}