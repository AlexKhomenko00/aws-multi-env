locals {
  vpc_cidr = module.network_plan.vpc_cidrs["prod"]

  management_account_id = "024665166160"
  hub_account_id        = data.aws_ssm_parameter.account_id["hub"].insecure_value

  guardduty_agent_repository_arn = "arn:aws:ecr:eu-central-1:323658145986:repository/aws-guardduty-agent-fargate"

  services = {
    ui = {
      name = "ui"
      port = 8080
    }
  }
}
