# Get latest cluster version
data "google_container_engine_versions" "versions" {
  zone = "${var.zone}"
}

# Create the GKE cluster
resource "google_container_cluster" "vault" {
  name    = "vault"
  project = "${google_project.vault.project_id}"
  zone    = "${var.zone}"

  initial_node_count = "${var.num_vault_servers}"

  min_master_version = "${data.google_container_engine_versions.versions.latest_master_version}"
  node_version       = "${data.google_container_engine_versions.versions.latest_node_version}"

  logging_service    = "${var.kubernetes_logging_service}"
  monitoring_service = "${var.kubernetes_monitoring_service}"

  node_config {
    machine_type    = "${var.instance_type}"
    service_account = "${google_service_account.vault-server.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    tags = ["vault"]
  }

  depends_on = [
    "google_project_service.service",
    "google_kms_crypto_key_iam_member.vault-init",
    "google_storage_bucket_iam_member.vault-server",
    "google_project_iam_member.service-account",
  ]
}

# Provision IP
resource "google_compute_address" "vault" {
  name    = "vault-lb"
  region  = "${var.region}"
  project = "${google_project.vault.project_id}"

  depends_on = ["google_project_service.service"]
}

output "address" {
  value = "${google_compute_address.vault.address}"
}

output "project" {
  value = "${google_project.vault.project_id}"
}

output "region" {
  value = "${var.region}"
}

output "zone" {
  value = "${var.zone}"
}
