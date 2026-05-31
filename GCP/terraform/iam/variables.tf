variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_id" {
  description = "The account_id for the MinIO service account (e.g. 'minio-sa')"
  type        = string
  default     = "minio-sa"
}

variable "bucket_name" {
  description = "The GCS bucket name that this SA will be granted access to"
  type        = string
}
