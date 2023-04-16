resource "aws_iam_role" "app-instance-role" {
  name = var.app_instance_role_name
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "app"
    })
  )
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": ["ec2.amazonaws.com", "ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "app-instance-role-policy" {
  name = "${var.app_instance_role_name}-policy"
  role = aws_iam_role.app-instance-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [ "*" ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": [ "*" ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "sqs:*"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
              "s3:*"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": ["arn:aws:logs:*:*:*"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-ecs-role-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role = aws_iam_role.app-instance-role.name
}

resource "aws_iam_role_policy_attachment" "ecs-image-pull-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role = aws_iam_role.app-instance-role.name
}

resource "aws_iam_user" "ci_user" {
  name = "ci_user"
}

resource  "aws_iam_policy" "ci-user-policy" {
  name = "ci-user-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:GetRole"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "cloudformation:Describe*",
          "cloudformation:List*",
          "cloudformation:Get*",
          "cloudformation:PreviewStackUpdate",
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:ValidateTemplate"
      ],
      "Resource": [ "*" ]
    },
    {
        "Effect": "Allow",
        "Action": [ "s3:*" ],
        "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "lambda:GetFunction",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionConfiguration",
          "lambda:UpdateFunctionCode",
          "lambda:ListVersionsByFunction",
          "lambda:PublishVersion",
          "lambda:CreateAlias",
          "lambda:DeleteAlias",
          "lambda:UpdateAlias",
          "lambda:GetFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:InvokeFunction"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "apigateway:GET",
          "apigateway:HEAD",
          "apigateway:OPTIONS",
          "apigateway:PATCH",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:DELETE"
      ],
      "Resource": [
          "arn:aws:apigateway:*::/restapis",
          "arn:aws:apigateway:*::/restapis/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:DescribeLogGroups",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "events:DescribeRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:DeleteRule"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [ "ecs:*" ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": ["ssm:GetParameter*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetInvalidation",
          "cloudfront:ListDistributions",
          "cloudfront:ListInvalidations"
      ],
      "Resource": ["*"]
    }
  ]
}
  POLICY
}

resource "aws_iam_user_policy_attachment" "ci-user-policy_attachment" {
  user = aws_iam_user.ci_user.name
  policy_arn = aws_iam_policy.ci-user-policy.arn
}
