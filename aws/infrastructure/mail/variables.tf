variable "region" {
  type = string
  default = "eu-central-1"
}

# Those will be setup by our tf.sh wrapper script
variable "aws_account_id" {
}
variable "aws_profile" {
}
variable "stage" {
}

variable "domain_name" {
}
