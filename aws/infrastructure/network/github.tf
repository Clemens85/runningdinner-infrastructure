module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "1.7.1"

  github_repositories = [
    "Clemens85/runningdinner"
  ]
  iam_role_policy_arns = [
    aws_iam_policy.ci-user-policy.arn
  ]

}