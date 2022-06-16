terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 4.8.0"
    }

    helm = {
      version = ">= 2.5.0"
    }

    kubernetes = {
      version = ">= 2.10.0"
    }
  }
}
