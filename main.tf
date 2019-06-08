provider "aws" {
  region = "us-east-2"
}
### ++++++++++++++++++
resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = "${file(var.public_key_path)}"
}

#### AWS VPC Creation 
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "${var.environment_tag}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment_tag}"
  }
}

### ++++++++++++++++++

#### Subnet Creation 
resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
  tags = {
    Environment = "${var.environment_tag}"
  }
}
### ++++++++++++++++++

#### Route Table Creation 

resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"

route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }

tags = {
    Environment = "${var.environment_tag}"
  }
}
### ++++++++++++++++++

#### Route Table Association 
resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}
### ++++++++++++++++++

#### Security Group 
resource "aws_security_group" "sg_22" {
  name = "sg_22"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment_tag}"
  }
}
### ++++++++++++++++

#### AMI naming setup 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}
## ++++++++++++++

#### EC2 Launch Defination 
resource "aws_instance" "web-1" {

  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.ec2key.key_name}"
  subnet_id = "${aws_subnet.subnet_public.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]

connection {
  host = self.public_ip
  user = "ubuntu"
  private_key  = "${file(var.private_key_path)}"
}
provisioner "remote-exec" {
inline = [
	"sudo  mkdir -p /etc/nginx/sites-enabled/"
	]
}
provisioner "file" {
    source = "main-site.conf"
    destination = "/tmp/main-site.conf"
}
provisioner "remote-exec" {
inline = [
	"sudo apt-get update -y",
	"sudo apt-get install wget git curl zip unzip nginx -y",
        "sudo wget https://colorlibvault-divilabltd.netdna-ssl.com/personal.zip",
        "sudo unzip personal.zip",
        "sudo mkdir -p /var/www/html",
        "sudo mv -v personal/* /var/www/html/",
	"sudo cp -rv /tmp/main-site.conf /etc/nginx/sites-enabled/",
	"sudo /etc/init.d/nginx restart"
 ]
} 
}

## ++++++++++++++
output "public_ip" {
  value = "http://${aws_instance.web-1.public_ip}:8080"
}
