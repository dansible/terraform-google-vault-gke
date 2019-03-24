# Required
variable kms_keyring_name {
  description = "The name of the Cloud KMS KeyRing for asset encryption."
}

variable kms_key_name {
  description = "The name of the Cloud KMS Key used for asset encryption/decryption."
}

# Optional
variable "project" {
  description = "The name of the GCP project."
  default     = ""
}

variable "region" {
  description = "The GCP region for the infra."
  default     = "northamerica-northeast1"
}

variable "name" {
  description = "A string value to use as a prefix for all resource names."
  default     = "vault"
}

variable kms_location {
  description = "The location of your KMS keyring and key."
  default     = "global"
}

variable vault_ip_network_tier {
  description = "The networking tier used for configuring this address. This field can take the following values: PREMIUM or STANDARD."
  default     = "STANDARD"
}

variable cluster_machine_type {
  description = "The name of a Google Compute Engine machine type. Defaults to n1-standard-2."
  default     = "n1-standard-2"
}

variable "vault_image" {
  description = "Name and version of the Vault container image to deploy."
  default     = "vault:1.0.3"
}

variable "vault_init_image" {
  description = "Name and version of the Vault Init container image to deploy."
  default     = "sethvargo/vault-init:1.0.0"
}

variable "num_vault_pods" {
  description = "The number of Vault pods to deploy in a StatefulSet."
  default     = "3"
  type        = "string"
}

variable "vault_recovery_keys" {
  description = "Number of recovery keys to generate."
  default     = "5"
  type        = "string"
}

variable "vault_recovery_key_threshold" {
  description = "Number of recovery keys required for quorum. This must be less than or equal to vault_recovery_keys."
  default     = "3"
  type        = "string"
}

variable "service_account_iam_roles" {
  description = "The roles to apply to the Vault GCP Service Account."
  type        = "list"

  default = [
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/viewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectAdmin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
  ]
}

variable gke_oauth_scopes {
  description = "The set of Google API scopes to enable on the GKE nodes."
  type        = "list"

  default = [
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloudkms",
    "https://www.googleapis.com/auth/devstorage.read_write",
  ]
}

variable "storage_bucket_roles" {
  description = "The roles given to the Vault GCP Service Account for accessing the GCS Bucket resources."
  type        = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

variable "kms_crypto_key_roles" {
  description = "The roles given to the Vault GCP Service Account for interacting with Google KMS."
  type        = "list"

  default = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
  ]
}

variable "enable_pod_security_policy" {
  description = "Whether to enable the PodSecurityPolicy controller for this cluster. If enabled, pods must be valid under a PodSecurityPolicy to be created."
  default     = false
}

variable "enable_network_policy" {
  description = "Whether we should enable the network policy addon for the master. This must be enabled in order to enable network policy for the nodes. It can only be disabled if the nodes already do not have network policies enabled."
  default     = false
}
