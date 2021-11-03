terraform {
  required_version = ">= 1.0.0"

  required_providers {
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

    template = {
      version = ">= 2.2.0"
    }
  }
}
