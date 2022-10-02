variable "number_of_instances" {
    default = 1
  }
variable "region" {
  description = "AWS region for hosting our your network"
  default = "us-east-1"
}
variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default = "/home/*/Github-Runner.pem"
}
variable "key_name" {
  description = "Key name for SSHing into EC2"
  default = "ec2-Github-Runner"
}
variable "amis" {
  description = "Base AMI to launch the instances"
  default = {
  us-east-1 = "ami-08c40ec9ead489470"
  }
}
 