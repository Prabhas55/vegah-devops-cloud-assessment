resource "aws_security_group" "dr_sg" {
  name        = "vegah-dr-security-group"
  description = "Security group for VEGAH DR server"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "HTTP application access"
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

  tags = merge(local.common_tags, {
    Name = "vegah-dr-security-group"
  })
}
