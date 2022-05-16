terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      version = ">= 2.5.0"
    }

    kubernetes = {
      version = ">= 2.5.0"
    }
  }
}
