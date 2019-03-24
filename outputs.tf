output "address" {
  value = "${google_compute_address.vault.address}"
}

# Output the initial root token
output "root_token" {
  value = "${data.google_kms_secret.keys.plaintext}"
}

# Uncomment this if you want to decrypt the token yourself
# output "root_token_decrypt_command" {
#   value = "gsutil cat gs://${google_storage_bucket.vault.name}/root-token.enc | base64 --decode | gcloud kms decrypt --project ${google_project.vault.project_id} --location ${var.region} --keyring ${google_kms_key_ring.vault.name} --key ${google_kms_crypto_key.vault-init.name} --ciphertext-file - --plaintext-file -"
# }

output "kubeconfig" {
  # sensitive = true
  value = "${module.k8s.kubeconfig}"
}

# Extra outputs
output "endpoint" {
  value = "${module.k8s.endpoint}"
}

output "cluster_ca_certificate" {
  sensitive = true
  value     = "${module.k8s.cluster_ca_certificate}"
}

output "client_certificate" {
  sensitive = true
  value     = "${module.k8s.client_certificate}"
}

output "client_key" {
  sensitive = true
  value     = "${module.k8s.client_key}"
}

# Networking outputs
output "network_name" {
  value = "${module.k8s.network_name}"
}

output "subnet_name" {
  value = "${module.k8s.subnet_name}"
}

output "service_account" {
  value = "${module.k8s.service_account }"
}

output "service_account_key" {
  value = "${module.k8s.service_account_key}"
}

output "vault_cert" {
  value = "\n${tls_locally_signed_cert.vault.cert_pem}\n${tls_self_signed_cert.vault-ca.cert_pem}"
}
