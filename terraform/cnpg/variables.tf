
output "keycloak_db_password" {
    value = random_password.keycloak_password.result
}