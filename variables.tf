variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "192.168.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default = "192.168.1.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "us-east-2a"
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  default = "t2.micro"
}
variable "environment_tag" {
  description = "Environment tag"
  default = "Production"
}
variable "public_key_path" {
  description = "Public key path"
  default = "/Users/krypton/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Public key path"
  default = "/Users/krypton/.ssh/id_rsa"
}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}
