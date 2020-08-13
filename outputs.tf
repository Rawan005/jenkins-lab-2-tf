output "bastion_ip" {
  value = module.dev.bastion
}
output "webserver_public_dns" {
  value = module.dev.webserver_public_dns
}

output "webserver_public_ip" {
  value = module.dev.webserver_ip
}

output "private_key" {
  value = file(var.private_key_path)
}

output "public_key" {
  value = file(var.public_key_path)
}