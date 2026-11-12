data "aws_caller_identity" "current" {
  provider = aws.dr
}
data "aws_caller_identity" "primary" {
  provider = aws.primary
}

data "aws_vpc" "default" {
  provider = aws.dr
  default  = true
}

# Latest Ubuntu 24.04 LTS AMI published by Canonical (region-specific lookup)
data "aws_ssm_parameter" "ubuntu" {
  provider = aws.dr
  name     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "dr" {
  provider   = aws.dr
  key_name   = "vegah-dr"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "dr" {
  provider    = aws.dr
  name        = "vegah-dr-sg"
  description = "VEGAH DR host"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH (admin only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "HTTP (serves traffic after failover)"
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

  tags = { Name = "vegah-dr-sg", Project = "vegah-dr" }
}

# ---- IAM: S3 backups + SSM session access ----
data "aws_iam_policy_document" "assume_ec2" {
  provider = aws.dr
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dr" {
  provider           = aws.dr
  name               = "vegah-dr-instance-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  provider   = aws.dr
  role       = aws_iam_role.dr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "backup_access" {
  provider = aws.dr
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.backups.arn}/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups.arn]
  }
}

resource "aws_iam_role_policy" "backup_access" {
  provider = aws.dr
  name     = "vegah-dr-backup-access"
  role     = aws_iam_role.dr.id
  policy   = data.aws_iam_policy_document.backup_access.json
}

data "aws_iam_policy_document" "fencing" {
  provider = aws.dr

  statement {
    sid     = "StopMumbaiPrimary"
    actions = ["ec2:StopInstances"]
    resources = [
      "arn:aws:ec2:${var.primary_region}:${data.aws_caller_identity.primary.account_id}:instance/${var.primary_instance_id}"
    ]
  }

  statement {
    sid       = "DescribeInstancesForFencing"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "fencing" {
  provider = aws.dr
  name     = "vegah-dr-primary-fencing"
  role     = aws_iam_role.dr.id
  policy   = data.aws_iam_policy_document.fencing.json

  lifecycle {
    precondition {
      condition = (
        data.aws_caller_identity.primary.account_id ==
        data.aws_caller_identity.current.account_id
      )
      error_message = "Primary and DR AWS providers must use the same AWS account for this fencing policy."
    }
  }
}
resource "aws_iam_instance_profile" "dr" {
  provider = aws.dr
  name     = "vegah-dr-instance-profile"
  role     = aws_iam_role.dr.name
}

# ---- DR compute ----
resource "aws_instance" "dr" {
  provider               = aws.dr
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.instance_type
  key_name               = aws_key_pair.dr.key_name
  vpc_security_group_ids = [aws_security_group.dr.id]
  iam_instance_profile   = aws_iam_instance_profile.dr.name

  user_data = templatefile("${path.module}/user_data.sh", {
    repo_url    = var.repo_url
    repo_branch = var.repo_branch
  })
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = { Name = "vegah-dr", Project = "vegah-dr", Role = "dr-standby" }
  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy.backup_access,
    aws_iam_role_policy.fencing
  ]
}

resource "aws_eip" "dr" {
  provider = aws.dr
  instance = aws_instance.dr.id
  domain   = "vpc"
  tags     = { Name = "vegah-dr-eip", Project = "vegah-dr" }
}
