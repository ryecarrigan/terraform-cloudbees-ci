terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 3.61.0"
    }

    helm = {
      version = ">= 2.3.0"
    }

    # Not the same as hashicorp/http!
    http = {
      source  = "terraform-aws-modules/http"
      version = ">= 2.4.1"
    }

    kubernetes = {
      version = ">= 2.5.0"
    }

    null = {
      version = ">= 3.1.1"
    }

    tls = {
      version = ">= 3.1.0"
    }
  }
}
