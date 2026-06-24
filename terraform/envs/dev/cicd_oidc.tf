variable "github_org" {
  default = "djguerch-ops"
}

variable "github_repo" {
  default = "weather-data-lake"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_terraform" {
  name = "weather-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "kinesis_read" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_read" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_role_policy" "github_actions_write" {
  name = "weather-github-actions-write"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Write"
        Effect = "Allow"
        Action = ["s3:CreateBucket", "s3:PutBucket*", "s3:DeleteBucket*",
                  "s3:PutObject", "s3:DeleteObject", "s3:PutEncryptionConfiguration",
                  "s3:PutBucketVersioning", "s3:PutBucketPublicAccessBlock"]
        Resource = ["arn:aws:s3:::weather-*", "arn:aws:s3:::weather-*/*"]
      },
      {
        Sid    = "KinesisWrite"
        Effect = "Allow"
        Action = ["kinesis:CreateStream", "kinesis:DeleteStream",
                  "kinesis:TagResource", "kinesis:AddTagsToStream"]
        Resource = "arn:aws:kinesis:*:*:stream/weather-*"
      },
      {
        Sid    = "LambdaWrite"
        Effect = "Allow"
        Action = ["lambda:CreateFunction", "lambda:UpdateFunctionCode",
                  "lambda:UpdateFunctionConfiguration", "lambda:DeleteFunction",
                  "lambda:TagResource"]
        Resource = "arn:aws:lambda:*:*:function:weather-*"
      },
      {
        Sid    = "LambdaEventSourceMapping"
        Effect = "Allow"
        Action = ["lambda:CreateEventSourceMapping", "lambda:DeleteEventSourceMapping",
                  "lambda:UpdateEventSourceMapping"]
        Resource = "arn:aws:lambda:*:*:event-source-mapping:*"
      },
      {
        Sid    = "IAMWrite"
        Effect = "Allow"
        Action = ["iam:GetRole", "iam:CreateRole", "iam:DeleteRole",
                  "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
                  "iam:AttachRolePolicy", "iam:DetachRolePolicy",
                  "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
                  "iam:TagRole", "iam:PassRole", "iam:ListRoleTags",
                  "iam:ListInstanceProfilesForRole"]
        Resource = ["arn:aws:iam::*:role/weather-*",
                    "arn:aws:iam::*:role/weather-github-actions-role"]
      },
      {
        Sid    = "OIDCProvider"
        Effect = "Allow"
        Action = ["iam:GetOpenIDConnectProvider", "iam:CreateOpenIDConnectProvider",
                  "iam:DeleteOpenIDConnectProvider", "iam:TagOpenIDConnectProvider",
                  "iam:ListOpenIDConnectProviderTags"]
        Resource = "arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_terraform.arn
}