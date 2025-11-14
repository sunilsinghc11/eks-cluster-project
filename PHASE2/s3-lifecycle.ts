resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = "my-terraform-state-kk-prod"

  rule {
    id     = "DeleteOldTerraformStateObjects"
    status = "Enabled"

    expiration {
      days = 30  # Delete objects older than 30 days
    }

    noncurrent_version_expiration {
      days = 30  # Delete previous versions after 30 days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}