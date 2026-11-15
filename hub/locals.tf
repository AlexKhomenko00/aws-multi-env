locals {
  vpc_cidr             = module.network_plan.vpc_cidrs["hub"]
  hub_router_tag       = "tag:hub-router"
  tailscale_admins     = "group:admin"
  tailscale_developers = "group:developers"

  advertised_routes = join(",", [
    local.vpc_cidr,
    module.network_plan.vpc_cidrs["staging"],
    module.network_plan.vpc_cidrs["prod"],
  ])

  management_account_id = "024665166160"

  workload_account_ids = {
    for k, p in data.aws_ssm_parameter.account_id : k => p.insecure_value
  }

  live_attachment_states = ["initiating", "initiatingRequest", "pendingAcceptance", "pending", "available", "modifying", "rollingBack"]

  spoke_attachment_ids = {
    for k, d in data.aws_ec2_transit_gateway_attachments.spoke : k => d.ids[0] if length(d.ids) > 0
  }
}
