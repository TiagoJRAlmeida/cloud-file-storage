output "bucket_name" {
  description = "The name of the GCS bucket"
  value       = google_storage_bucket.minio_backend.name
}

output "bucket_url" {
  description = "The GCS URL of the bucket (gs://...)"
  value       = google_storage_bucket.minio_backend.url
}
