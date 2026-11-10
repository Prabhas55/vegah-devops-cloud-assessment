output "dr_vpc_id" {
  value = aws_vpc.dr_vpc.id
}

output "dr_subnet_id" {
  value = aws_subnet.dr_public_subnet.id
}

output "dr_security_group_id" {
  value = aws_security_group.dr_sg.id
}

output "dr_instance_id" {
  value = aws_instance.dr_server.id
}

output "dr_public_ip" {
  value = aws_instance.dr_server.public_ip
}

output "dr_iam_role" {
  value = aws_iam_role.dr_ssm_role.name
}
