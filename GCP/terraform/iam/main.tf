resource "google_service_account" "minio_sa" {
  account_id   = var.service_account_id
  display_name = "MinIO Service Account"
  description  = "Used by MinIO to read/write objects in GCS"
  project      = var.project_id
}

# Grant the SA object-level access on the bucket only (least privilege)
resource "google_storage_bucket_iam_member" "minio_sa_binding" {
  bucket = var.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.minio_sa.email}"
}

# Generate a JSON key so MinIO can authenticate as this SA
resource "google_service_account_key" "minio_sa_key" {
  service_account_id = google_service_account.minio_sa.name
}
