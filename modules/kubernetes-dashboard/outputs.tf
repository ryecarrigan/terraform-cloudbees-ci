output "token" {
  value = data.kubernetes_secret.this.data["token"]
}
