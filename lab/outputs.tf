output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "webserver_public_dns" {
  value = aws_instance.webserver.0.public_dns
}

output "webserver_ip" {
  value = aws_instance.webserver.0.public_ip
}