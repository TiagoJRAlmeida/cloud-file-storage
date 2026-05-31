terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 7.28" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source     = "./network"
  project_id = var.project_id
  region     = var.region
}

module "cluster" {
  source       = "./cluster"
  project_id   = var.project_id
  zone         = var.zone
  cluster_name = var.cluster_name
  node_count   = var.node_count
  machine_type = var.machine_type
  network_id   = module.network.network_id
  subnet_id    = module.network.subnet_id
}
