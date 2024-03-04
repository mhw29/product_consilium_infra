variable "host" {
    type = string
    description = "The Kubernetes cluster host"
}

variable "username" {
    type = string
    description = "The Kubernetes cluster username"
}

variable "password" {
    type = string
    description = "The Kubernetes cluster password"
}

variable "client_certificate" {
    type = string
    description = "The Kubernetes cluster client certificate"
}

variable "client_key" {
    type = string
    description = "The Kubernetes cluster client key"
}

variable "cluster_ca_certificate" {
    type = string
    description = "The Kubernetes cluster CA certificate"
}

