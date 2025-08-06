# This requires the runningdinner-functions CDK to be deployed first !!!
data "aws_s3_bucket" "route-optimization-bucket" {
  bucket = var.route_optimization_bucket_name
}

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
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "${data.aws_s3_bucket.route-optimization-bucket.arn}/*",
            "${data.aws_s3_bucket.route-optimization-bucket.arn}"
          ]
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
        "iam:GetRole",
        "iam:CreateRole",
        "iam:DeleteRolePolicy",
        "iam:PutRolePolicy",
        "iam:List*",
        "iam:PassRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:TagRole",
        "iam:UntagRole"
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
          "cloudformation:ValidateTemplate",
          "cloudformation:DeleteChangeSet",
          "cloudformation:CreateChangeSet",
          "cloudformation:ExecuteChangeSet"
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
          "lambda:*"
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
          "logs:*"
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