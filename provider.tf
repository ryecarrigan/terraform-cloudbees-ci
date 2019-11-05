provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "remote" {
    organization = "ryecodes"
    workspaces {
      name = "tf-core-modern"
    }
  }
}
