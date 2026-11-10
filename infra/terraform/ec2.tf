resource "aws_instance" "dr_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.dr_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.dr_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.dr_instance_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "vegah-dr-server"
  })

  depends_on = [
    aws_iam_role_policy_attachment.ssm_policy
  ]
}
