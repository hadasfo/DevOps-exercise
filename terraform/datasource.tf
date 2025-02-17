resource "grafana_data_source" "postgresql" {
  type              = "postgres"
  name              = "PostgreSQL"
  url               = var.pg_host
  database_name     = var.pg_database
  username          = var.pg_user      
  access_mode       = "proxy"
  basic_auth_enabled = false

  json_data_encoded = jsonencode({
    sslmode         = "disable"
    timescaledb     = false
  })

  secure_json_data_encoded = jsonencode({
    password = var.pg_password
  })
}