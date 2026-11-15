terraform {
  required_version = ">= 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~>0.29"
    }
  }

  backend "s3" {
    key                  = "hub/terraform.tfstate"
    workspace_key_prefix = "hub"
    region               = "eu-central-1"
    use_lockfile         = true
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment        = "hub"
      ManagedBy          = "terraform"
      Owner              = "oleksandr.khomenko2000@gmail.com"
      DataClassification = "internal"
      Project            = "landing-zone"
    }
  }
}

provider "tailscale" {}
