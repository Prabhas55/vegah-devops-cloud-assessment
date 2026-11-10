resource "aws_iam_role" "dr_ssm_role" {
  name = "vegah-dr-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.dr_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "dr_instance_profile" {
  name = "vegah-dr-ec2-instance-profile"
  role = aws_iam_role.dr_ssm_role.name

  tags = local.common_tags
}
