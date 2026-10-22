provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket       = "innovatech-tfstate-453809273733"
    key          = "case-study-2/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}