# This file contains all the interactions with Google Cloud

provider "google" {
  region  = "${var.region}"
  zone    = "${var.zone}"
  project = "${var.project}"
}

# Generate a random id for the project - GCP projects must have globally
# unique names
resource "random_id" "random" {
  prefix      = "vault-"
  byte_length = "8"
}

# Create the project
resource "google_project" "sample" {
  name            = "${random_id.random.hex}"
  project_id      = "${random_id.random.hex}"
  org_id          = "${var.org_id}"
  billing_account = "${var.billing_account}"
}

# Create the project service account
resource "google_service_account" "gke-sa" {
  account_id   = "gke-sa"
  display_name = "gke-sa"
  project      = "${google_project.vault.project_id}"
}

# Create a service account key
resource "google_service_account_key" "vault" {
  service_account_id = "${google_service_account.gke-sa.name}"
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = "${length(var.service_account_iam_roles)}"
  project = "${google_project.vault.project_id}"
  role    = "${element(var.service_account_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = "${length(var.project_services)}"
  project = "${google_project.vault.project_id}"
  service = "${element(var.project_services, count.index)}"

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  
disable_on_destroy = false

}

