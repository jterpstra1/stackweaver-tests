variable "AWS_PROFILE" {
  type    = string
  default = "default"
}

variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "AWS_ACCESS_KEY_ID" {
  type    = string
  default = ""
}

variable "AWS_SECRET_ACCESS_KEY" {
  type    = string
  default = ""
}

variable "AWS_ASSUME_ROLE_ARN" {
  type    = string
  default = null
}

# Test variable for StackWeaver variable integration testing
# This variable should be set in StackWeaver workspace variables to test the integration
variable "test_var" {
  type        = string
  description = "Test variable for StackWeaver integration testing"
  default     = "default-value"
}