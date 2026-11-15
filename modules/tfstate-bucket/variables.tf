variable "namespace" {
  description = "Label namespace, e.g. acme."
  type        = string
}

variable "environment" {
  description = "Label environment (region code), e.g. euc1."
  type        = string
}

variable "stage" {
  description = "Label stage: the account the bucket belongs to, e.g. org, hub, staging or prod."
  type        = string
}
