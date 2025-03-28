# Output public IP
output "instance_ip" {
  value = aws_instance.cherry_instance.public_ip
}
