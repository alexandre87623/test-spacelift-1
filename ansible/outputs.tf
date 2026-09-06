# Output pour afficher l'IP
output "aws_instances" {
  description = "IP publique pour PuTTY"
  value       = [aws_instance.vm_debian.public_ip]
}

