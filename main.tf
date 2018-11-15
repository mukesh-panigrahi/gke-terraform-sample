# Create the storage bucket
resource "google_storage_bucket" "vault" {
  name          = "${google_project.vault.project_id}-vault-storage"
  project       = "${google_project.vault.project_id}"
  force_destroy = true
  storage_class = "MULTI_REGIONAL"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 3
    }
  }

  depends_on = ["google_project_service.service"]
}

# Grant service account access to the storage bucket
resource "google_storage_bucket_iam_member" "vault-server" {
  count  = "${length(var.storage_bucket_roles)}"
  bucket = "${google_storage_bucket.vault.name}"
  role   = "${element(var.storage_bucket_roles, count.index)}"
  member = "serviceAccount:${google_service_account.vault-server.email}"
}

# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = "vault"
  location = "${var.region}"
  project  = "${google_project.vault.project_id}"

  depends_on = ["google_project_service.service"]
}

# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-init" {
  name            = "vault-init"
  key_ring        = "${google_kms_key_ring.vault.id}"
  rotation_period = "604800s"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-init" {
  count         = "${length(var.kms_crypto_key_roles)}"
  crypto_key_id = "${google_kms_crypto_key.vault-init.id}"
  role          = "${element(var.kms_crypto_key_roles, count.index)}"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}


#####################################################################
# Modules
#####################################################################
module "ci-cluster" {
  source   = "./gke-cluster/ci-cluster"
  project  = "${var.project}"
  region   = "${var.region}"
  username = "${var.username}"
  password = "${var.password}"
}

module "prod-cluster" {
  source   = "./gke-cluster/prod-cluster"
  host     = "${module.gke.host}"
  username = "${var.username}"
  password = "${var.password}"
}
module "git-repo" {
  source   = "./git-repo"
  project  = "${var.project}"
  region   = "${var.region}"
  username = "${var.username}"
  password = "${var.password}"
}

module "gcr" {
  source   = "./gcr"
  project  = "${var.project}"
  region   = "${var.region}"
  username = "${var.username}"
  password = "${var.password}"
}

  client_certificate     = "${module.gke.client_certificate}"
  client_key             = "${module.gke.client_key}"
  cluster_ca_certificate = "${module.gke.cluster_ca_certificate}"

