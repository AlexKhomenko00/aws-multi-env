module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = "acme"
  environment = "euc1"
  stage       = "staging"
}
