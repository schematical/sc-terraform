output "vpc_id" {
  value = aws_vpc.main.id
}
output "private_subnet_mappings" {
  value = aws_subnet.private_subnets
}
output "public_subnet_mappings" {
  value = aws_subnet.private_subnets
}