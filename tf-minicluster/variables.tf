resource "random_password" "k3stoken" {
  length  = 32
  special = false
}
