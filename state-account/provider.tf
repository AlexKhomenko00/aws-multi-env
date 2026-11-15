terraform {
  required_version = ">= 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }

  backend "s3" {
    bucket       = "acme-euc1-org-tfstate-024665166160-eu-central-1-an"
    key          = "state-account/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment        = "org"
      ManagedBy          = "terraform"
      Owner              = "oleksandr.khomenko2000@gmail.com"
      DataClassification = "internal"
      Project            = "landing-zone"
    }
  }
}

provider "aws" {
  alias  = "tfstate"
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["tfstate"]}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Environment        = "tfstate"
      ManagedBy          = "terraform"
      Owner              = "oleksandr.khomenko2000@gmail.com"
      DataClassification = "internal"
      Project            = "landing-zone"
    }
  }
}
