# Terraform Foundation

## 6.0 Deliverable

| Phase | Deliverable                    |
| ----- | ------------------------------ |
| 6.1   | Terraform foundation/standards |
| 6.2   | VPC module                     |
| 6.3   | KMS module                     |
| 6.4   | IAM module                     |
| 6.5   | ECR module                     |
| 6.6   | EKS module                     |
| 6.7   | RDS module                     |
| 6.8   | Redis module                   |
| 6.9   | Secrets module                 |
| 6.10  | Observability module           |
| 6.11  | Dev environment                |
| 6.12  | Staging environment            |
| 6.13  | Production environment         |
| 6.14  | Terraform tests                |
| 6.15  | CI/CD integration              |
| 6.16  | Security hardening             |
| 6.17  | Documentation/runbooks         |

So after 6.1, the Terraform foundation should look like:

```
terraform/
├── README.md
│
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── redis/
│   ├── ecr/
│   ├── iam/
│   ├── kms/
│   ├── secrets/
│   └── observability/
│
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
│
└── global/
    ├── backend/
    └── iam/
```

## 6.1 Target structure

```
terraform/
│
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── redis/
│   ├── ecr/
│   ├── iam/
│   ├── kms/
│   ├── secrets/
│   └── observability/
│
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
│
└── global/
    ├── backend/
    └── iam/
```
## 6.1.1 Terraform Version

```
Terraform >= 1.14.0
Terraform < 2.0.0

# The CI workflow pins: 1.14.6
```

## 6.1.2 AWS Provider
The provider itself will be configured at the environment root, rather than independently inside every reusable module.
```
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0"
  }
}
```

## 6.1.3 Naming Convention
ObservaStack resources should follow:

```
observastack-<environment>-<component>
```
Example

```
observastack-dev-vpc
observastack-dev-eks
observastack-dev-rds
observastack-dev-redis
observastack-dev-ecr
```
For production

```
observastack-production-vpc
observastack-production-eks
observastack-production-rds
```

Avoid hardcoding names inside inividual modules. Instead:

```
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
```

## 6.1.4 Standard Tags

Every AWS resource that supports tagging should receive a consistent baseline.

Our foundation standard will be:

```
default_tags {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.repository
    Owner       = "ObservaStack"
  }
}
```

For example:

```
Project     = ObservaStack
Environment = dev
ManagedBy   = Terraform
Repository  = Emmy-github-webdev/observastack
Owner       = ObservaStack
Component   = VPC
```

## 6.1.5 Environment Isolation

Each environment remains an independent Terraform root module:

```
terraform/environments/dev
terraform/environments/staging
terraform/environments/production
```

Each gets its own state:

```
s3://emmy-github-webdev-observastack/
    observastack/dev/terraform.tfstate

    observastack/staging/terraform.tfstate

    observastack/production/terraform.tfstate
```

## 6.1.6 Environment Provider

Each environment will eventually contain something like:

```
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = var.repository
      Owner       = "ObservaStack"
    }
  }
}
```

## 6.1.7 Module Contract

Every reusable module should follow this pattern:

```
terraform/modules/<module>/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

Optional:

```
├── locals.tf
├── data.tf
└── validation.tf
```

1. _versions.tf_

- Defines:
  - Terraform version
  - provider requirements

2. _variables.tf_

- Defines:
  - inputs
  - types
  - descriptions
  - validation
  - defaults

3. _main.tf_
Contains the actual resources.

4. _outputs.tf_
Exposes only values needed by consumers.

5. _README.md_

6. _Documents_:
  - purpose
  - inputs
  - outputs
  - architecture
  - security considerations
  - usage example

## 6.1.8 No Provider Configuration Inside Modules

This is worth making an explicit project rule. Good:

```
environments/dev/
       │
       └── provider.aws
              │
              ▼
        modules/vpc
```
This keeps the modules portable.

## 6.1.9 State Security

The environment state bucket created by our bootstrap process will have:

```
S3 Versioning
Public Access Block
BucketOwnerEnforced
Server-side encryption
Secure transport enforcement
```
And we should treat Terraform state as sensitive infrastructure data.
Therefore:

```
DO NOT
├── commit *.tfstate
├── commit *.tfstate.*
├── commit .terraform/
├── commit crash.log
└── commit *.tfplan
```

Our root .gitignore should contain:

```
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log

# Terraform variable files containing secrets
*.tfvars
*.tfvars.json
!example.tfvars
```

## 6.1.10 Sensitive Variables

Secrets must never be hard-coded:

Bad:
```
password = "MySuperSecretPassword"
```

Instead:

```
variable "database_password" {
  type      = string
  sensitive = true
}
```
Eventually, for ObservaStack, application secrets should be integrated with AWS Secrets Manager and External Secrets rather than being stored directly in Terraform configuration.

That will become part of the secrets module.

## 6.1.11 Terraform Validation Standard

Every module must pass:

```
terraform fmt -check
terraform init -backend=false
terraform validate
```

Environment roots must pass:

```
terraform fmt -check
terraform init
terraform validate
terraform plan
```

Security checks will additionally run through our existing GitHub Actions pipeline.

## 6.1.12 Foundation Design Decision

The most important architectural rule for Volume 6 is:

```
                    Terraform
                       │
          ┌────────────┴────────────┐
          │                         │
       Global                  Environments
          │                         │
    ┌─────┴─────┐          ┌───────┼────────┐
    │           │          │       │        │
 Backend       IAM        Dev    Staging  Production
    │           │          │       │        │
    └───────────┘          └───────┼────────┘
                                   │
                              Reusable modules
                                   │
             ┌─────────┬──────────┼─────────┬─────────┐
             ▼         ▼          ▼         ▼         ▼
            VPC       EKS        RDS      Redis      ECR
```