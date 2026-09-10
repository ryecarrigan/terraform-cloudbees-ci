terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      version = ">= 3.0.0"
    }

    kubernetes = {
      version = ">= 3.0.0"
    }
  }
}
