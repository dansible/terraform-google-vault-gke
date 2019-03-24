# Pull Access Token from gcloud client config: https://www.terraform.io/docs/providers/google/d/datasource_client_config.html
data "google_client_config" "gcloud" {}

provider "kubernetes" {
  load_config_file       = false
  host                   = "${module.k8s.endpoint}"
  token                  = "${data.google_client_config.gcloud.access_token}"
  cluster_ca_certificate = "${base64decode(module.k8s.cluster_ca_certificate)}"
}

# Write the secret
resource "kubernetes_secret" "vault-tls" {
  metadata {
    name = "vault-tls"
  }

  data {
    "vault.pem" = "${tls_locally_signed_cert.vault.cert_pem}\n${tls_self_signed_cert.vault-ca.cert_pem}"
    "vault.key" = "${tls_private_key.vault.private_key_pem}"
  }
}

# Render the YAML file
data "template_file" "vault" {
  template = "${file("${path.module}/k8s/vault.yaml")}"

  vars {
    gcs_bucket_name              = "${google_storage_bucket.vault.name}"
    kms_region                   = "${var.kms_location}"
    kms_key_ring                 = "${var.kms_keyring_name}"
    kms_crypto_key               = "${var.kms_key_name}"
    load_balancer_ip             = "${google_compute_address.vault.address}"
    num_vault_pods               = "${var.num_vault_pods}"
    project                      = "${var.project}"
    vault_image                  = "${var.vault_image}"
    vault_init_image             = "${var.vault_init_image}"
    vault_recovery_keys          = "${var.vault_recovery_keys}"
    vault_recovery_key_threshold = "${var.vault_recovery_key_threshold}"
  }
}

# Submit the job - Terraform doesn't yet support StatefulSets, so we have to shell out.
resource "null_resource" "apply" {
  triggers {
    host                   = "${md5(module.k8s.endpoint)}"
    token                  = "${md5(data.google_client_config.gcloud.access_token)}"
    cluster_ca_certificate = "${md5(module.k8s.cluster_ca_certificate)}"
  }

  depends_on = ["kubernetes_secret.vault-tls"]

  provisioner "local-exec" {
    command = <<EOF
gcloud container clusters get-credentials "${var.name}" --region="${var.region}" --project="${var.project}"
CONTEXT="gke_${var.project}_${var.region}_${var.name}"
echo '${data.template_file.vault.rendered}' | kubectl apply --context="$CONTEXT" -f -
EOF
  }
}

# Wait for all the servers to be ready
resource "null_resource" "wait-for-finish" {
  provisioner "local-exec" {
    command = <<EOF
for i in $(seq -s " " 1 15); do
  sleep $i
  if [ $(kubectl get pod | grep vault | wc -l) -eq ${var.num_vault_pods} ]; then
    exit 0
  fi
done
echo "Pods are not ready after 2m"
exit 1
EOF
  }

  depends_on = ["null_resource.apply"]
}

# Build the URL for the keys on GCS
data "google_storage_object_signed_url" "keys" {
  bucket      = "${google_storage_bucket.vault.name}"
  path        = "root-token.enc"
  credentials = "${base64decode(module.k8s.service_account_key)}"
  depends_on  = ["null_resource.wait-for-finish"]
}

# Download the encrypted recovery unseal keys and initial root token from GCS
data "http" "keys" {
  url        = "${data.google_storage_object_signed_url.keys.signed_url}"
  depends_on = ["null_resource.wait-for-finish"]
}

# Decrypt the values
data "google_kms_secret" "keys" {
  crypto_key = "projects/${var.project}/locations/${var.kms_location}/keyRings/${var.kms_keyring_name}/cryptoKeys/${var.kms_key_name}"
  ciphertext = "${data.http.keys.body}"
}
