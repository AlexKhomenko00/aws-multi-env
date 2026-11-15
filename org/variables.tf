variable "budget_limit" {
  type    = string
  default = "10"
}

variable "email" {
  description = "Mailbox for budget and anomaly alerts. Every member account's root email is a plus-address of it: <user>+<account>-<random>@<domain>."
  type        = string
  default     = "oleksandr.khomenko2000@gmail.com"

  validation {
    condition     = length(split("@", var.email)) == 2
    error_message = "email must be a single address like name@example.com."
  }
}
