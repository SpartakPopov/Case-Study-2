terraform {
  required_version = ">= 1.10" // use_lockfile in the S3 backend needs 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" // allows 6.x updates but not a jump to 7.0
    }
  }
}
