resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com" // url for aws to fetch Github public keys for verification thet they werent forged
  client_id_list = ["sts.amazonaws.com"]                         // the client that the token is for
}

// creating a role usable by workflows
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"

  assume_role_policy = jsonencode({ // for transforming into json 
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn } // basically who is allowed to assume the role (in this case the github actions OIDC provider)
      Action    = "sts:AssumeRoleWithWebIdentity"                            // this is HOW it can assume it
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"                                  // token must be meant for AWS STS
          "token.actions.githubusercontent.com:sub" = "repo:SpartakPopov/Case-Study-2:ref:refs/heads/main" // only workflows running on the main branch of this repo
        }
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess" // already existing AWS policy
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
