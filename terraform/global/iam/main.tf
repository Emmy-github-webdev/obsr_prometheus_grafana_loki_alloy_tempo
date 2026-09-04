provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project    = "ObservaStack"
        ManagedBy  = "Terraform"
        Component  = "GitHubOIDC"
        Repository = "observastack"
      },
      var.tags
    )
  }
}

data "aws_caller_identity" "current" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repository}:environment:dev",
        "repo:${var.github_org}/${var.github_repository}:environment:staging",
        "repo:${var.github_org}/${var.github_repository}:environment:production",
        "repo:${var.github_org}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

data "aws_iam_policy_document" "terraform_bootstrap" {
  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:PutBucketOwnershipControls",
      "s3:GetBucketEncryption",
      "s3:PutBucketEncryption",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformStateObjects"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::observastack-terraform-state-*/*"]
  }
}

resource "aws_iam_role" "terraform_bootstrap" {
  name               = "${var.role_prefix}-bootstrap"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json

  max_session_duration = 3600
}

resource "aws_iam_role_policy" "terraform_bootstrap" {
  name   = "bootstrap-state-backend"
  role   = aws_iam_role.terraform_bootstrap.id
  policy = data.aws_iam_policy_document.terraform_bootstrap.json
}

data "aws_iam_policy_document" "terraform_plan" {
  statement {
    sid       = "ReadOnlyInfrastructure"
    effect    = "Allow"
    actions   = ["ec2:Describe*", "eks:Describe*", "ecr:Describe*", "rds:Describe*", "elasticache:Describe*", "iam:Get*", "iam:List*", "kms:Describe*", "secretsmanager:DescribeSecret", "s3:Get*", "s3:List*"]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::observastack-terraform-state-*"]
  }

  statement {
    sid       = "TerraformStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::observastack-terraform-state-*/*"]
  }
}

resource "aws_iam_role" "terraform_plan" {
  name               = "${var.role_prefix}-plan"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

resource "aws_iam_role_policy" "terraform_plan" {
  name   = "terraform-plan"
  role   = aws_iam_role.terraform_plan.id
  policy = data.aws_iam_policy_document.terraform_plan.json
}

data "aws_iam_policy_document" "terraform_apply" {
  statement {
    sid       = "TerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::observastack-terraform-state-*"]
  }

  statement {
    sid       = "TerraformStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::observastack-terraform-state-*/*"]
  }

  statement {
    sid       = "InfrastructureProvisioning"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "terraform_apply" {
  name               = "${var.role_prefix}-apply"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

resource "aws_iam_role_policy" "terraform_apply" {
  name   = "terraform-apply"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.terraform_apply.json
}
