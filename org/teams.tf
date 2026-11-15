resource "aws_identitystore_group" "network" {
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  display_name      = "network"
  description       = "Network team - owns hub"
}

resource "aws_identitystore_group" "product" {
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  display_name      = "product"
  description       = "Product team - owns staging and prod"
}

resource "aws_ssoadmin_permission_set" "network_view_only" {
  name             = "NetworkViewOnly"
  description      = "Read-only view of networking: VPC, TGW, RAM, flow logs"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT2H"
}

data "aws_iam_policy_document" "network_view_only" {
  statement {
    sid = "NetworkDescribe"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNatGateways",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeAddresses",
      "ec2:DescribeManagedPrefixLists",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeTransitGatewayAttachments",
      "ec2:DescribeTransitGatewayVpcAttachments",
      "ec2:DescribeTransitGatewayRouteTables",
      "ec2:GetTransitGatewayRouteTableAssociations",
      "ec2:GetTransitGatewayRouteTablePropagations",
      "ec2:SearchTransitGatewayRoutes",
      "ram:GetResourceShares",
      "ram:GetResourceShareAssociations",
      "ram:ListResources",
      "ram:ListPrincipals",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "LogsList"
    actions   = ["logs:DescribeLogGroups", "logs:GetQueryResults"]
    resources = ["*"]
  }

  statement {
    sid = "FlowLogsRead"
    actions = [
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:StartQuery",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/vpc/*/flow-logs",
      "arn:aws:logs:*:*:log-group:/vpc/*/flow-logs:*",
    ]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "network_view_only" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.network_view_only.arn
  inline_policy      = data.aws_iam_policy_document.network_view_only.json
}

locals {
  team_assignments = {
    "network-hub-admin"     = { group = aws_identitystore_group.network.group_id, account = local.account_ids["hub"], permission_set = aws_ssoadmin_permission_set.admin.arn }
    "network-staging-view"  = { group = aws_identitystore_group.network.group_id, account = local.account_ids["staging"], permission_set = aws_ssoadmin_permission_set.network_view_only.arn }
    "network-prod-view"     = { group = aws_identitystore_group.network.group_id, account = local.account_ids["prod"], permission_set = aws_ssoadmin_permission_set.network_view_only.arn }
    "product-staging-admin" = { group = aws_identitystore_group.product.group_id, account = local.account_ids["staging"], permission_set = aws_ssoadmin_permission_set.admin.arn }
    "product-prod-admin"    = { group = aws_identitystore_group.product.group_id, account = local.account_ids["prod"], permission_set = aws_ssoadmin_permission_set.admin.arn }
    "product-hub-view"      = { group = aws_identitystore_group.product.group_id, account = local.account_ids["hub"], permission_set = aws_ssoadmin_permission_set.network_view_only.arn }
  }
}

resource "aws_ssoadmin_account_assignment" "team" {
  for_each = local.team_assignments

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = each.value.permission_set
  principal_id       = each.value.group
  principal_type     = "GROUP"
  target_id          = each.value.account
  target_type        = "AWS_ACCOUNT"
}
