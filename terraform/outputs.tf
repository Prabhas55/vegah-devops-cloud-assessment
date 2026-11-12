output "dr_public_ip" {
  value = aws_eip.dr.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_eip.dr.public_ip}"
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}

output "app_url" {
  value = var.domain_name != "" ? (
    var.record_name == "" ? "http://${var.domain_name}" : "http://${var.record_name}.${var.domain_name}"
  ) : "(DNS failover not enabled yet)"
}
