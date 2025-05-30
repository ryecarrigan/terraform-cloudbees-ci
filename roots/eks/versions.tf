terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 5.99.0"
    }

    helm = {
      version = ">= 2.17.0"
    }

    kubernetes = {
      version = ">= 2.37.0"
    }
  }
}
