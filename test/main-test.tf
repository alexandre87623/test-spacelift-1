terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3" # Paris
}

# 1. Image officielle Debian 12
data "aws_ami" "debian12" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Groupe de sécurité (Port 22 ouvert)
resource "aws_security_group" "sg_ssh" {
  name        = "debian12-password-sg"
  description = "Autoriser SSH via Mot de passe"

  ingress {
    from_port   = 22
    to_port     = 22
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

# 3. Instance EC2 (Sans clé SSH requise)
resource "aws_instance" "vm_debian" {
  ami                    = data.aws_ami.debian12.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg_ssh.id]

  # Script d'initialisation pour activer la connexion par mot de passe
  user_data = <<-EOF
              #!/bin/bash
              # 1. Changer le mot de passe de l'utilisateur admin
              echo 'admin:admin!' | chpasswd

              # 2. Activer l'authentification par mot de passe dans OpenSSH
              sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^Include \/etc\/ssh\/sshd_config.d\/\*.conf/# Include \/etc\/ssh\/sshd_config.d\/\*.conf/' /etc/ssh/sshd_config

              # 3. Redémarrer le service SSH
              systemctl restart ssh
              EOF

  tags = {
    Name = "VM-Debian12-Password"
  }
}

# Output pour afficher l'IP
output "public_ip" {
  description = "IP publique pour PuTTY"
  value       = aws_instance.vm_debian.public_ip
}