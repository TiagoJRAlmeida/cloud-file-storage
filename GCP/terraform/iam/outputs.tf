output "service_account_email" {
  description = "The email of the MinIO service account"
  value       = google_service_account.minio_sa.email
}

output "service_account_key_json" {
  description = "Base64-encoded JSON key for the MinIO service account"
  value       = google_service_account_key.minio_sa_key.private_key
  sensitive   = true
}
