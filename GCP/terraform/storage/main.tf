resource "google_storage_bucket" "minio_backend" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = false

  # Prevents accidental public exposure
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 7 # days — cleans up stale incomplete uploads
    }
  }
}
