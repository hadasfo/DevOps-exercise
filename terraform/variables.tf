# PostgreSQL Host and Database Variables
variable "pg_host" {
  default = "postgresql.default.svc.cluster.local:5432"
}

variable "pg_database" {
  default = "devops"
}

variable "pg_user" {
  default = "postgres"
}


variable "pg_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}
