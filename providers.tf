# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
terraform {
  backend "remote" {
    hostname     = "stack.truyens.pro"
    organization = "mike"
    # token = "<YOUR_TOKEN>"
    token = ""
    workspaces {
      name = "mike"
    }
  }

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
#    aws = {
#      source  = "hashicorp/aws"
#      version = ">=6.0.0,<7.0.0"
#    }
  }

}

# provider "aws" {
#   profile    = var.AWS_PROFILE
#   region     = var.AWS_REGION
#   access_key = var.AWS_ACCESS_KEY_ID
#   secret_key = var.AWS_SECRET_ACCESS_KEY

#   dynamic "assume_role" {
#     for_each = var.AWS_ASSUME_ROLE_ARN != null ? [1] : []
#     content {
#       role_arn = var.AWS_ASSUME_ROLE_ARN
#     }
#   }
# }
