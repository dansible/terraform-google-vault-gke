# Generate self-signed TLS certificates
resource "tls_private_key" "vault-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "vault-ca" {
  key_algorithm         = "${tls_private_key.vault-ca.algorithm}"
  private_key_pem       = "${tls_private_key.vault-ca.private_key_pem}"
  validity_period_hours = 8760
  is_ca_certificate     = true

  subject {
    common_name  = "vault-ca.local"
    organization = "HashiCorp Vault"
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ${path.module}/tls/ca.pem && chmod 0600 ${path.module}/tls/ca.pem"
  }
}

# Create the Vault server certificates
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = "2048"

  provisioner "local-exec" {
    command = "echo '${self.private_key_pem}' > ${path.module}/tls/vault.key && chmod 0600 ${path.module}/tls/vault.key"
  }
}

# Create the request to sign the cert with our CA
resource "tls_cert_request" "vault" {
  key_algorithm   = "${tls_private_key.vault.algorithm}"
  private_key_pem = "${tls_private_key.vault.private_key_pem}"

  dns_names = [
    "vault",
    "vault.local",
    "vault.default.svc.cluster.local",
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1",
    "${google_compute_address.vault.address}",
  ]

  subject {
    common_name  = "vault.local"
    organization = "HashiCorp Vault"
  }
}

# Now sign the cert
resource "tls_locally_signed_cert" "vault" {
  cert_request_pem      = "${tls_cert_request.vault.cert_request_pem}"
  ca_key_algorithm      = "${tls_private_key.vault-ca.algorithm}"
  ca_private_key_pem    = "${tls_private_key.vault-ca.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.vault-ca.cert_pem}"
  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ${path.module}/tls/vault.pem && echo '${tls_self_signed_cert.vault-ca.cert_pem}' >> ${path.module}/tls/vault.pem && chmod 0600 ${path.module}/tls/vault.pem"
  }
}
