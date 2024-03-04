variable "postgres_username" {
    description = "PostgreSQL username"
    type        = string
}

variable "postgres_password" {
    description = "PostgreSQL password"
    type        = string
}

variable "postgres_dbname" {
    description = "PostgreSQL database name"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group in which to create the PostgreSQL server"
    type        = string
}

variable "resource_group_location" {
    description = "The location/region where the PostgreSQL server will be created"
    type        = string
}

