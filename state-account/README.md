# state-account

The one Terraform state bucket for hub, staging and prod. It lives in its own
account, `tfstate`, which `org/` creates and which holds nothing else.

It runs with management credentials, once, after `org/`. It reads the account
IDs that `org/` published (`/org/accounts/{tfstate,hub,staging,prod}`), steps
into the tfstate account through `OrganizationAccountAccessRole` (the admin
role Organizations creates in every account it creates), and builds the bucket
with `modules/tfstate-bucket/`, the same module `org-bucket/` uses.

```sh
AWS_PROFILE=<management-profile> terraform init
AWS_PROFILE=<management-profile> terraform apply
terraform output -raw backend_config
```

That value goes to the first init of hub, staging and prod, all the same:
`terraform init -backend-config="bucket=..."`. Each of them still logs in to
its own account; the bucket lets them in from there.

`org/`'s state is not here. It stays in `org-bucket/`'s bucket in management,
because `org/` creates the tfstate account and can't keep its state in an
account that doesn't exist yet.

## Who can do what in the bucket

| Account              | Can                 | Only on                                     |
| -------------------- | ------------------- | ------------------------------------------- |
| every member account | read and write      | `<env>/terraform.tfstate`                   |
| every member account | read, write, delete | `<env>/terraform.tfstate.tflock` (the lock) |
| every member account | list                | keys under `<env>/`                         |
| tfstate (owner)      | everything          | —                                           |

"Every member account" means every account `org/` publishes under
`/org/accounts/` in management (hub, staging, prod and security today), except tfstate
itself. A new account added in `org/` gets its own `<name>/` prefix on the next
apply here, with nothing to list by hand.

Anything not over HTTPS is refused. The bucket keeps every version, and no
member account may delete the state file itself, so a team can't wipe its own
history even though it is admin in its own account.

Each folder sets `workspace_key_prefix` to its own name. `terraform init`
lists workspaces, under `env:/` by default, and that listing would be outside
the prefix the account is allowed to see.

The bucket keeps the S3 default "bucket owner enforced": no ACLs, and whatever
hub, staging or prod writes is owned by the tfstate account. It's encrypted
with S3's own key (SSE-S3), which needs no extra grants across accounts; a KMS
key would need its key policy opened to each account too.

## Why it isn't part of `org/`

Terraform has to know a provider's settings before it can plan anything with
that provider. A provider that logs in to the tfstate account needs that
account's ID, and while `org/` is still creating the account, the ID doesn't
exist yet. `org/` once had an `aws.hub` provider for exactly this and it
failed. A second folder that runs afterwards reads the ID as a plain, already
known value, so its provider can be set up normally.

## Why a fifth account

Four accounts was the plan, and adding more was resisted on purpose. State is
the exception because there is no good place for it among the four:

- **In management**: the management account should hold only what has to be
  there, since guardrails don't apply to it.
- **In each account, next to what it describes**: whoever is admin in prod can
  also delete or rewrite prod's state, and every account carries its own copy
  of the bucket setup.
- **In hub**: hub belongs to the network team, who shouldn't own the product
  team's state.

A dedicated account holding only state is what HashiCorp's S3 backend docs
and AWS's own Account Factory for Terraform both do. It costs one account with
one bucket in it, and the bucket policy gives every team its own file and
nothing else.

## Sources

- [Terraform: S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
  — suggests one state bucket in a separate administrative account, with roles
  for each environment. Lists the exact permissions: `ListBucket`, Get/Put on
  the key, Get/Put/Delete on `<key>.tflock`; an `s3:prefix` condition on
  listing; partial backend config with `-backend-config`.
- [AFT: Terraform and AFT versions](https://docs.aws.amazon.com/controltower/latest/userguide/version-supported.html)
  — with plain Terraform, AWS's Account Factory for Terraform keeps state
  centrally in `aft-backend-*` buckets in its own AFT management account (not
  the organization's management account).
- [AFT: remove an account](https://docs.aws.amazon.com/controltower/latest/userguide/aft-remove-account.html)
  — that central bucket has a folder per account, the same layout as here.
- [AFT: required roles](https://docs.aws.amazon.com/controltower/latest/userguide/aft-required-roles.html)
  — the AFT pipeline assumes an admin role inside each account, the same move
  as assuming `OrganizationAccountAccessRole` here.
- [AFT: account customizations](https://docs.aws.amazon.com/controltower/latest/userguide/aft-account-customization-options.html)
  — a baseline applied to accounts after they are created, as its own stage.
- [Terraform: provider configuration](https://developer.hashicorp.com/terraform/language/providers/configuration)
  — provider arguments can only use values known before apply. The reason this
  is a separate folder.
- [AWS Organizations: best practices for the management account](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices_mgmt-acct.html)
  — keep resources out of the management account, since SCPs don't restrict it.
- [AWS Organizations: OrganizationAccountAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create-cross-account-role.html)
  — created by default in accounts Organizations creates, assumable from
  management.
- [Amazon S3: Object Ownership](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
  — "bucket owner enforced" is the default for new buckets; the bucket owner
  owns every object, whoever uploaded it.
- [Amazon S3: namespaces for general purpose buckets](https://docs.aws.amazon.com/en_us/AmazonS3/latest/userguide/gpbucketnamespaces.html)
  — the `-<account id>-<region>-an` naming, and only the owning account can
  create buckets in it.
- [AWS Prescriptive Guidance: Terraform backend best practices](https://docs.aws.eu/prescriptive-guidance/latest/terraform-aws-provider-best-practices/backend.html)
  — **partly goes the other way:** recommends a separate backend (a distinct
  S3 bucket) per environment, so access can be granted per bucket. Here
  isolation comes from per-key permissions in one shared bucket, which is
  finer-grained and easier to get wrong.
- [AWS whitepaper: benefits of using multiple AWS accounts](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/benefits-of-using-multiple-aws-accounts.html)
  — accounts as the boundary for ownership and for limiting the impact of a
  mistake. This cuts both ways: it's the reason for a dedicated account, but
  it also argues for keeping each account's data inside that account.
