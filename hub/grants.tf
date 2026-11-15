resource "tailscale_acl" "grants" {
  acl = <<-EOF
  {
    "groups": {
      "${local.tailscale_admins}": ["oleksandr.khomenko2000@gmail.com"],
      "${local.tailscale_developers}": [],
    },

    "tagOwners": {
      "${local.hub_router_tag}": ["${local.tailscale_admins}"],
    },

    "grants": [
      {
        "src": ["${local.tailscale_admins}", "${local.tailscale_developers}"],
        "dst": ["${local.hub_router_tag}", "${module.network_plan.supernet}"],
        "ip":  ["*"],
      },
    ],

    "autoApprovers": {
      "routes": {
        "${local.vpc_cidr}": ["${local.hub_router_tag}"],
        "${module.network_plan.vpc_cidrs["staging"]}": ["${local.hub_router_tag}"],
        "${module.network_plan.vpc_cidrs["prod"]}": ["${local.hub_router_tag}"],
      },
    },
  }
  EOF
}
