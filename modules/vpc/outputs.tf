output "vpc_id" {
  value = aws_vpc.main.id
}
output "private_subnet_mappings" {
  value = aws_subnet.private_subnets
}
output "public_subnet_mappings" {
  value = aws_subnet.public_subnets
}
output "bastion_security_group" {
  value = aws_security_group.bastion.id
}
output "bastion_private_key_pem" {
  value = tls_private_key.bastion_private_key.private_key_openssh
}
output "bastion_arn" {
  value = var.bastion_keypair_name != "" ? aws_instance.bastion[0].arn : 0
}
output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}
output "public_route_table_id" {
  value = aws_route_table.public_route_table.id
}