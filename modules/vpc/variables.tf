variable "name" {
  description = "Prefix used for the Name tag on every resource this module creates."
  type        = string
}

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 28
    error_message = "vpc_cidr must have a prefix length between /16 and /28."
  }
}

variable "azs" {
  description = "Availability zone names to spread subnets across, e.g. [\"eu-central-1a\", \"eu-central-1b\"]."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "azs must contain at least one availability zone."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Assigned to azs by index, cycling through var.azs if there are more CIDRs than AZs."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each public_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs :
      tonumber(split("/", cidr)[1]) >= 16 && tonumber(split("/", cidr)[1]) <= 28
    ])
    error_message = "Each public_subnet_cidrs entry must have a prefix length between /16 and /28."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (NAT-egress) subnets. Assigned to azs by index, cycling through var.azs if there are more CIDRs than AZs."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each private_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs :
      tonumber(split("/", cidr)[1]) >= 16 && tonumber(split("/", cidr)[1]) <= 28
    ])
    error_message = "Each private_subnet_cidrs entry must have a prefix length between /16 and /28."
  }
}

variable "isolated_subnet_cidrs" {
  description = "CIDR blocks for isolated (no-egress) subnets. Optional tier - leave empty to skip it. Assigned to azs by index, cycling through var.azs if there are more CIDRs than AZs."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.isolated_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each isolated_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for cidr in var.isolated_subnet_cidrs :
      tonumber(split("/", cidr)[1]) >= 16 && tonumber(split("/", cidr)[1]) <= 28
    ])
    error_message = "Each isolated_subnet_cidrs entry must have a prefix length between /16 and /28."
  }
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign a public IPv4 to instances launched in public subnets, unless the instance itself overrides it."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "true = one NAT gateway shared by every private subnet. false = one NAT gateway per AZ that has a private subnet."
  type        = bool
  default     = true
}

variable "endpoints" {
  description = "VPC endpoints keyed by service short name (com.amazonaws.<region>.<key>). Gateway endpoints attach to the private and isolated route tables; Interface endpoints go in the private subnets, each behind its own rule-less security group (see endpoint_security_group_ids)."
  type = map(object({
    type = string
  }))
  default = {
    s3       = { type = "Gateway" }
    dynamodb = { type = "Gateway" }
  }

  validation {
    condition     = alltrue([for e in values(var.endpoints) : contains(["Gateway", "Interface"], e.type)])
    error_message = "Each endpoint type must be \"Gateway\" or \"Interface\"."
  }
}

variable "enable_flow_logs" {
  description = "Create a VPC-wide flow log."
  type        = bool
  default     = true
}

variable "flow_log_traffic_type" {
  description = "Traffic type captured by the flow log."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention, in days, for the flow log group."
  type        = number
  default     = 14
}
