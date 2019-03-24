# Versioning
##########################################################
terraform {
  required_version = ">= 0.11.9"

  required_providers {
    google = ">= 1.19.1"
  }
}

# Google Provider info
##########################################################
provider "google" {
  version = "~> 1.19"
  region  = "${var.region}"
}

provider "google-beta" {
  version = "~> 1.19"
  region  = "${var.region}"
}

# Create the storage bucket
##########################################################
resource "google_storage_bucket" "vault" {
  name          = "${var.name}"
  project       = "${var.project}"
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
      num_newer_versions = 1
    }
  }
}

# Grant service account access to the storage bucket
##########################################################
resource "google_storage_bucket_iam_member" "vault-server" {
  count  = "${length(var.storage_bucket_roles)}"
  bucket = "${google_storage_bucket.vault.name}"
  role   = "${element(var.storage_bucket_roles, count.index)}"
  member = "serviceAccount:${module.k8s.service_account}"
}

# Grant service account access to the key
##########################################################
resource "google_kms_crypto_key_iam_member" "vault-init" {
  count         = "${length(var.kms_crypto_key_roles)}"
  crypto_key_id = "projects/${var.project}/locations/${var.kms_location}/keyRings/${var.kms_keyring_name}/cryptoKeys/${var.kms_key_name}"
  role          = "${element(var.kms_crypto_key_roles, count.index)}"
  member        = "serviceAccount:${module.k8s.service_account}"
}

# Provision a Public IP for Vault
##########################################################
resource "google_compute_address" "vault" {
  name         = "${var.name}"
  region       = "${var.region}"
  project      = "${var.project}"
  network_tier = "${var.vault_ip_network_tier}"
}

# Private GKE Cluster
##########################################################
module "k8s" {
  source                    = "git@github.com:dansible/terraform-google_gke_infra.git?ref=v0.5.1"
  name                      = "${var.name}"
  project                   = "${var.project}"
  region                    = "${var.region}"
  enable_legacy_kubeconfig   = false
  private_cluster           = true
  node_tags                 = ["${var.name}"]
  service_account_iam_roles = "${var.service_account_iam_roles}"
  oauth_scopes              = "${var.gke_oauth_scopes}"

  node_options = {
    disk_size    = 20
    disk_type    = "pd-standard"
    image        = "COS"
    machine_type = "${var.cluster_machine_type}"
    preemptible  = false
  }

  k8s_options = {
    binary_authorization       = false
    enable_hpa                 = true
    enable_http_load_balancing = true
    enable_dashboard           = false
    enable_network_policy      = "${var.enable_network_policy}"
    enable_pod_security_policy = "${var.enable_pod_security_policy}"
    logging_service            = "logging.googleapis.com"
    monitoring_service         = "monitoring.googleapis.com"
  }
}
