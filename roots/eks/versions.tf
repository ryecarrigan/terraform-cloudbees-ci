terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 5.99.0, <6.0.0"
    }

    helm = {
      version = ">= 2.17.0, <3.0.0"
    }

    http = {
      version = ">= 3.5.0"
    }

    kubernetes = {
      version = ">= 2.37.0"
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
