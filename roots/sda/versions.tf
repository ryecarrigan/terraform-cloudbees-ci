terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      version = ">= 2.5.0"
    }

    kubernetes = {
      version = ">= 2.5.0"
    }

    template = {
      version = ">= 2.2.0"
    }

    time = {
      version = ">= 0.7.2"
    }
  }
}
