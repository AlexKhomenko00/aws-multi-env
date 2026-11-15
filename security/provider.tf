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
    key          = "security/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  alias  = "management"
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment        = "security"
      ManagedBy          = "terraform"
      Owner              = "oleksandr.khomenko2000@gmail.com"
      DataClassification = "internal"
      Project            = "landing-zone"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  assume_role {
    role_arn     = "arn:aws:iam::${data.aws_ssm_parameter.security_account_id.insecure_value}:role/OrganizationAccountAccessRole"
    session_name = "terraform-security"
  }

  default_tags {
    tags = {
      Environment        = "security"
      ManagedBy          = "terraform"
      Owner              = "oleksandr.khomenko2000@gmail.com"
      DataClassification = "internal"
      Project            = "landing-zone"
    }
  }
}
