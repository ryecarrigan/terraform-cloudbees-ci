terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 6.0.0"
    }

    helm = {
      version = ">= 3.0.0"
    }

    http = {
      version = ">= 3.5.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }

    kubernetes = {
      version = ">= 3.0.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.3"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.1"
    }
  }
}
