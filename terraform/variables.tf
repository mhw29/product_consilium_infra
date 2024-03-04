variable "postgres_username" {
    description = "PostgreSQL username"
    type        = string
}

variable "postgres_password" {
    description = "PostgreSQL password"
    type        = string
}
variable "sa_name" {
  type    = string
  default = "external-secrets-operator"
}
variable "sa_namespace" {
  type        = string
  description = "The namespace where the service account will be created"
  default     = "external-secrets-operator"
}