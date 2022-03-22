provider "kubernetes" {
  config_path = var.kubeconfig_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_file
  }
}
