terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 3.61.0"
    }

    helm = {
      version = ">= 2.3.0"
    }

    kubernetes = {
      version = ">= 2.5.0"
    }
  }
}
