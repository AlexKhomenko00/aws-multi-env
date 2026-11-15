# security

GuardDuty and the audit log for the whole organization.

GuardDuty runs from the **security** account. It reads AWS's own logs and
flags things that look like an attack: stolen keys in use, traffic to known bad
addresses, odd logins. Findings stay in the security account's GuardDuty
console; nothing sends them anywhere yet.

Separate from `org/` because `org/` creates the security account, and
Terraform can't configure an account in the same apply that creates it.

## Audit log

| What          | Where                                             | Why                                                         |
| ------------- | ------------------------------------------------- | ----------------------------------------------------------- |
| org trail     | management (`aws.management`)                     | only management or a delegated admin can own an org trail   |
| log bucket    | security (default provider)                       | outside management, the one account SCPs can't reach        |
| Object Lock   | governance, 30 days default retention             | deletes need an explicit bypass; compliance can't be undone |
| bucket policy | AWS's org-trail template, trail ARN in management | CloudTrail writes only for this trail                       |

The trail lives here, not in `org/`, because it needs the bucket first.

## How accounts are covered

| Account                     | How                                               |
| --------------------------- | ------------------------------------------------- |
| security                    | GuardDuty's admin for the organization            |
| hub, staging, prod, any new | enrolled automatically (`auto_enable = ALL`)      |
| management                  | added by hand: AWS's auto-enroll skips management |

## What's watched

Always: AWS API calls, VPC traffic and DNS lookups.

Extras, set in one list in `guardduty.tf`:

| Extra              | On? | Why                                                         |
| ------------------ | --- | ----------------------------------------------------------- |
| S3 access          | yes | reads and deletes on the state and audit-log buckets        |
| Database logins    | yes | brute-force or unknown logins to the catalog database       |
| Runtime monitoring | yes | process, file and network activity inside the Fargate tasks |
| EC2 malware scans  | no  | the Tailscale machine is the only EC2                       |
| EKS, Lambda, AI    | no  | none of those run here                                      |

Runtime monitoring details:

| Setting          | Value                                   | Why                                                     |
| ---------------- | --------------------------------------- | ------------------------------------------------------- |
| Fargate agent    | managed by GuardDuty                    | the only option on Fargate; added to each new task      |
| EC2, EKS agents  | off                                     | no EKS; the Tailscale machine isn't Systems Manager-run |
| Image pull       | execution roles, one GuardDuty repo     | the agent is pulled with the task's own role            |
| Memory           | up to 128 MB per task                   | staging UI raised to 1 GB to fit it next to the JVM     |
| Network          | through NAT, no endpoint or rule needed | tasks already reach ECR and S3 on 443                   |
| Running services | redeploy once after enabling            | the agent only joins tasks started afterwards           |

Roughly $6/month (~$11 with prod fully scaled out), after a 30-day free trial
per account. Runtime monitoring is $1.92 per Fargate vCPU per month.

## Teardown

Removing GuardDuty here leaves it running in the other accounts. To stop it
there too, suspend them first, then destroy. An SCP blocks this for everyone
except `OrganizationAccountAccessRole`, so run it as that role in the security
account:

```sh
aws guardduty stop-monitoring-members --detector-id <security detector id> \
  --account-ids <hub id> <staging id> <prod id>
```

The log bucket stays until it's emptied, with
`x-amz-bypass-governance-retention` on each delete.

## Sources

- [GuardDuty with AWS Organizations](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_organizations.html)
- [Auto-enable for organization members](https://docs.aws.amazon.com/guardduty/latest/ug/set-guardduty-auto-enable-preferences.html)
- [RDS Protection (supported engines)](https://docs.aws.amazon.com/guardduty/latest/ug/rds-protection.html)
- [Runtime Monitoring on Fargate](https://docs.aws.amazon.com/guardduty/latest/ug/prereq-runtime-monitoring-ecs-support.html)
- [Fargate agent repositories](https://docs.aws.amazon.com/guardduty/latest/ug/ecs-runtime-agent-ecr-image-uri.html)
- [How the agent connects](https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-agent-connectivity.html)
- [Pricing](https://aws.amazon.com/guardduty/pricing/)
- [Bucket policy for an organization trail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html#org-trail-bucket-policy)
- [Organization trails from the CLI (management or delegated admin)](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-and-update-an-organizational-trail-by-using-the-aws-cli.html)
- [S3 Object Lock: governance vs compliance](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
