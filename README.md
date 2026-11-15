# aws-multi-env

A multi-account AWS landing zone in Terraform, for a made-up online shop. It's a
working draft that shows the structure and the trade-offs: a useful starting
point, not a production-grade platform (see
[Not production-grade](#not-production-grade)). Every folder passes
`terraform validate`; it hasn't been applied end to end yet.

## Scenario

A mid-sized EU web shop. Customers browse a product catalog; that's the only
feature modeled. Everything is sized from these numbers:

| Assumed                    |                                   |
| -------------------------- | --------------------------------- |
| Monthly / daily users      | 100,000 / 15,000                  |
| Online at the evening peak | 1,500                             |
| Page requests              | ~150/s at peak, ~50/s rest of day |

The app is AWS's public retail sample: a Java front end (**UI**) asking a Go
service (**Catalog**) for products stored in MySQL.

## Accounts

| Account    | Holds                                               |
| ---------- | --------------------------------------------------- |
| management | the organization, logins, guardrails, the org trail |
| hub        | shared network: the link between environments, VPN  |
| staging    | a small copy of the shop                            |
| prod       | the shop                                            |
| tfstate    | one bucket with every environment's Terraform state |
| security   | GuardDuty for the whole organization, the audit log |

Each folder is treated as a different team's (platform, network, product), so
teams never read each other's state and every cross-account link is explicit.

## Decisions

| Area               | Chosen                                                                 | Why                                                                                 |
| ------------------ | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Networking         | hub-and-spoke Transit Gateway                                          | one place to connect environments; staging and prod can't reach each other          |
| Engineer access    | one Tailscale subnet router in hub                                     | no open SSH/VPN ports; login keys come from AWS identity, no stored secret          |
| Guardrails         | SCPs: no leaving the org, CloudTrail or GuardDuty tampering, 2 regions | apply to every member account                                                       |
| Logins             | Identity Center groups, admin only where a team owns                   | cross-team access is read-only and networking-only                                  |
| Terraform state    | one bucket in its own account, one file per account                    | teams can't delete their own history; nothing extra in management                   |
| Cross-account IDs  | SSM parameters shared via RAM, plus AWS lookups                        | no copying IDs by hand, no reading another team's state                             |
| Database           | MySQL, one writer + standby in another zone                            | ~300 simple reads/s fits one server; about a third of Aurora's cost                 |
| App sizing         | UI ½ CPU / 1 GB, Catalog ¼ CPU, 3–6 copies each                        | measured locally: ~100 and ~65 req/s per copy at 70% CPU                            |
| Spare capacity     | 3 copies on regular capacity, extras split evenly with Spot            | the minimum can't be taken away; bursts are cheap                                   |
| AWS service access | through NAT; free gateway endpoints for S3/DynamoDB                    | interface endpoints would cost ~$105/month in prod for little saving                |
| Container images   | private registry mirroring the public images                           | versions pinned in our account                                                      |
| Audit log          | org trail in management, logs in a bucket in security                  | logs kept out of management, the one account SCPs can't reach                       |
| Log retention      | Object Lock, governance mode, 30 days                                  | a month to notice and investigate; governance so it can still be removed on purpose |
| Threat detection   | GuardDuty org-wide, S3, database-login and Fargate runtime on          | ~$6/month; runtime sees what runs inside the containers                             |
| Spend              | monthly budget + anomaly alerts                                        | alerts at 80%/100% spent, 90% forecast, and any spike worth 40% of the budget       |

## Gotchas

- **SCPs never apply to management.** Its admins can still stop the trail;
  logs already delivered sit in security, locked.
- **Governance lock isn't absolute.** Anyone with
  `s3:BypassGovernanceRetention` (security's admins, management via
  `OrganizationAccountAccessRole`) can still delete logs.
- **The trail is created by `security/`, not `org/`.** It needs its bucket
  first, and the bucket can only be made after `org/` creates the account.
- **A provider can't use an account created in the same apply.** That's why
  anything _inside_ new accounts (`state-account/`, `security/`) is its own
  folder, run after `org/`.
- **Hub is applied twice.** Spokes can only ask to join the Transit Gateway
  after it exists; hub finds and accepts them on the second run, no flags.
- **Closing an account takes 90 days**, AWS limits how many close per month,
  and its email can never be reused (hence a random suffix per account).
- **Immediate cost-anomaly alerts only go to SNS**, not straight to email.
  Confirm the subscription email after the first `org/` apply.
- **GuardDuty's auto-enable skips management**; it's added as a member by hand.
- **AWS rotates the database password every 7 days**, but Catalog reads it
  only at start.

## Cost

Frankfurt list prices, November 2026:

| What      | Cost             | Mostly                                              |
| --------- | ---------------- | --------------------------------------------------- |
| prod      | ~$0.45/hour      | 3 NAT gateways, 6 Fargate tasks, Multi-AZ database  |
| staging   | a fraction of it | 1 NAT gateway, 2 small tasks, single database       |
| GuardDuty | ~$6/month        | Fargate runtime, activity logs, S3, database logins |

## Setup

**Needs:** Terraform ≥ 1.17, AWS CLI v2, an existing Organization with IAM
Identity Center (its account becomes management), and a Tailscale OAuth client
in `TAILSCALE_OAUTH_CLIENT_ID` / `TAILSCALE_OAUTH_CLIENT_SECRET`.

**Once, in management:** enable the SCP policy type on the root, CloudTrail
trusted access, and `aws ram enable-sharing-with-aws-organization`.

**Apply in order.** Steps 1–4 run with management credentials;
`state-account/` and `security/` reach into their accounts through
`OrganizationAccountAccessRole`. Hub, staging and prod run logged in to their
own account.

1. `org-bucket/` — state bucket for `org/`
2. `org/` — accounts, guardrails, logins, budget
3. `state-account/` — the shared state bucket; its `backend_config` output is
   what hub, staging and prod pass to `terraform init -backend-config=...`
4. `security/` — GuardDuty, audit-log bucket, org trail
5. `hub/`
6. `staging/`, `prod/`
7. `hub/` again, to accept staging and prod

## Destroy

`prod/` and `staging/`, then `hub/`. `org/`, `security/` and the state buckets
normally stay. Before removing `security/`, suspend GuardDuty in the member
accounts ([security/README.md](security/README.md#teardown)), or it keeps
running there. Its log bucket only goes once emptied with the governance
bypass. Destroying `org/` closes the member accounts.

## Not production-grade

Deliberately left out of this draft:

- HTTPS: the public load balancer serves plain HTTP until a domain and an
  ACM certificate are added
- a dedicated log-archive account, compliance-mode lock, longer retention
- Security Hub, AWS Config, alerting on findings, on-call
- least-privilege roles below "team admin", and CI/CD with per-account roles
- central egress inspection and IP address management
- a second Tailscale router (one router is a single point of failure)
- load balancing between services (ECS Service Connect or an internal ALB);
  UI finds Catalog through plain DNS
- disaster recovery to another region
- deletion protection and final snapshots on prod's database
- password rotation picked up without a restart
- a real load test; the sizing above comes from a local test
