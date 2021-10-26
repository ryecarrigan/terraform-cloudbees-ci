terraform {
  required_version = ">= 1.0.0"

  backend "s3" {}

  required_providers {
    helm = {
      version = ">= 2.3.0"
    }

    kubernetes = {
      version = ">= 2.5.0"
    }

    template = {
      version = ">= 2.2.0"
    }
  }
}
