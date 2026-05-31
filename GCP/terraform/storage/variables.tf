variable "bucket_name" {
  description = "Name of the GCS bucket used as MinIO backend (must be globally unique)"
  type        = string
}

variable "region" {
  description = "GCP region where the bucket will be created"
  type        = string
}
