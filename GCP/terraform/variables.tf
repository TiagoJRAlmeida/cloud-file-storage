variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "primary-cluster"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for cluster nodes"
  type        = string
  default     = "e2-small"
}

variable "minio_bucket_name" {
  description = "Globally unique name for the GCS bucket used as MinIO backend"
  type        = string
  default     = "minio-bucket"
}

variable "minio_sa_id" {
  description = "account_id for the MinIO GCP service account"
  type        = string
  default     = "minio-sa"
}
