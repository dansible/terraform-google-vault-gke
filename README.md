# Vault on GKE

This Terraform module provisions a `GKE cluster` and deploys `Vault` onto it. It's based on [Seth Vargo's Vault on GKE](https://github.com/sethvargo/vault-on-gke) project.

- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Interact with Vault](#interact-with-vault)
- [Module Details](#module-details)
  - [Input Variables](#input-variables)
  - [Output Variables](#output-variables)
  - [FAQ](#faq)
- [Links](#links)

## Prerequisites

A `Google KMS Key` and `Keyring` are required to deploy this module.

> **NOTE:** These cannot be created/managed by Terraform as Keyrings cannot be deleted from a project in GCP at the moment (see: https://cloud.google.com/kms/docs/faq#cannnot_delete).

```sh
gcloud kms keyrings create vault-keyring --location global
gcloud kms keys create vault-key --location global --keyring vault-keyring --purpose encryption
```

## Usage

```hcl
module "vault" {
  source           = "git@github.com:dansible/terraform-google-vault-gke.git?ref=v0.0.6"
  name             = "${var.team-name}"
  project          = "${var.project}"
  kms_keyring_name = "${var.keyring_name}"
  kms_key_name     = "${var.key_name}"
}
```

### Interact with Vault

When Terraform has finished provisioning your resources, you can interact with Vault using the following steps:

1. Export the Vault variables:

```sh
export VAULT_ADDR="https://$(terraform output address):8200"
export VAULT_CAPATH="tls/ca.pem"
export VAULT_TOKEN="$(terraform output token)"
```

2. Run some commands

```sh
vault kv put secret/foo a=b
```

## Module Details

This module:
- Creates a `GCS bucket` to store all Vault data.
- Uses `Google KMS key` for encryption/decryption of Vault tokens.
- Creates a `GCP Service Account` with the most restrictive permissions to those resources.
- Creates a `GKE Cluster` with the configured service account attached.
- Reserves a `Public IP` for Vault.
- Generates a `self-signed certificate authority (CA)`.
- Generates a `certificate signed by that CA`.
- Configures Terraform to talk to K8s.
- Creates a `K8s Secret` with the TLS file contents.
- Configures your local system to talk to the GKE cluster by getting the `cluster credentials` and `k8s context`.
- Deploys Vault to the GKE cluster using a `3-Pod StatefulSet` and a `K8s Service`.

### Input Variables

| Variable               | Description                           | Default                                                    |
| :----------------------- | :----------------------------------    | :---------------------------------------------------------- |
| `kms_keyring_name` | The name of the Cloud KMS KeyRing for asset encryption. | **(required)** |
| `kms_key_name` | The name of the Cloud KMS Key used for asset encryption/decryption. | **(required)** |
| `project` | The name of the GCP project. | `""` |
| `region` | The GCP region for the infra. | `northamerica-northeast1` |
| `name` | A string value to use as a prefix for all resource names. | `vault` |
| `kms_location` | The location of your KMS keyring and key. | `global` |
| `vault_ip_network_tier` | The networking tier used for configuring this address. | `STANDARD` |
| `cluster_machine_type` | The name of a Google Compute Engine machine type. | `n1-standard-2` |
| `vault_image` | Name and version of the Vault container image to deploy. | `vault:1.0.3` |
| `vault_init_image` | Name and version of the Vault Init container image to deploy.  | `sethvargo/vault-init:1.0.0` |
| `num_vault_pods` | The number of Vault pods to deploy in a StatefulSet. | `3` |
| `vault_recovery_keys` | Number of recovery keys to generate. | `1` |
| `vault_recovery_key_threshold` | Number of recovery keys required for quorum. This must be less than or equal to vault_recovery_keys. | `1` |
| `service_account_iam_roles` | The roles to apply to the Vault GCP Service Account. | see [variables file](./variables.tf) |
| `gke_oauth_scopes` | The set of Google API scopes to enable on the GKE nodes. | see [variables file](./variables.tf) |
| `storage_bucket_roles` | The roles given to the Vault GCP Service Account for accessing the GCS Bucket resources. | see [variables file](./variables.tf) |
| `kms_crypto_key_roles` | The roles given to the Vault GCP Service Account for interacting with Google KMS. | see [variables file](./variables.tf) |

### Output Variables

| Variable               | Description                           |
| :----------------------- | :---------------------------------- |
| `address` | The Public IP used to reach Vault. |
| `token` | The Vault root token. |
| `kubeconfig` | The kubeconfig for Vault's GKE cluster. |
| `endpoint` | The API endpoint for Vault's GKE cluster. |
| `cluster_ca_certificate` | The CA certificate for Vault's GKE cluster. |
| `client_certificate` | The Client certificate for Vault's GKE cluster. |
| `client_key` | The Client Certificate Key for Vault's GKE cluster. |
| `network_name` | The name of the VPC created by this module. |
| `subnet_name` | The name of the Subnet created by this module. |
| `service_account` | The Service Account created by this module. |
| `service_account_key` | The Key for the Service Account created by this module. |
| `vault_cert` | The certificate chain for the Vault deployment. |

### FAQ

**Q: Why are you using StatefulSets instead of Deployments?**

A: StatefulSets ensure that each pod is deployed in order. This is important for the initial bootstrapping process, otherwise there's a race for which Vault server initializes first with auto-init.

**Q: Why didn't you use the Terraform Kubernetes provider to create the pods? There's this hacky template_file data source instead...**

A: StatefulSets currently don't support Affinity rules. Waiting for this issue to be resolved: https://github.com/terraform-providers/terraform-provider-kubernetes/issues/233

## Links

- [Original Terraform code](https://github.com/sethvargo/vault-on-gke)
- [GKE Vault tutorial that the setup is based on](https://codelabs.developers.google.com/codelabs/vault-on-gke/index.html)
- [kelseyhightower/vault-on-google-kubernetes-engine](https://github.com/kelseyhightower/vault-on-google-kubernetes-engine)
