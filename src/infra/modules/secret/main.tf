# --- Secrets ---
resource "random_password" "postgres" {
  length           = 16
  special          = true
  override_special = "!#&*()-_+[]{}<>"
}

resource "aws_secretsmanager_secret" "postgres" {
  name                    = var.secret_name
  description             = "PostgreSQL password."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = random_password.postgres.result
}
