variable "cockroachdb_namespace" {
  description = "The namespace of the cockroach databases"
  type        = string
}

variable "cockroachdb_image" {
  description = "CockroachDB Image"
  default     = "cockroachdb/cockroach:v24.1.0"
}

variable "cockroachdb_storage" {
  description = "CockroachDB k8s storage request"
  default     = "10Gi"
}

variable "image_pull_policy" {
  description = "K8s image pull policy"
  type        = string
}

