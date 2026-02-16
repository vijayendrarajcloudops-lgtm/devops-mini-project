provider "aws" {
  region = "ap-south-1"
}

resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file("/var/lib/jenkins/keys/ansible-key.pem.pub")
}


resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 ap-south-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "terraform-ansible-nginx"
  }
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory"
  content  = templatefile("${path.module}/inventory.tpl", {
    ec2_ip = aws_instance.web.public_ip
  })
}
