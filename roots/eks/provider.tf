provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_auth_token
  }
}
