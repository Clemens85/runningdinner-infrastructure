variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "region" {
  type = string
  default = "eu-central-1"
}

variable "az" {
  type = list
  default = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}


# Those will be setup by our tf.sh wrapper script
variable "aws_account_id" {
}
variable "aws_profile" {
}
variable "stage" {
}

variable "app_instance_name" {
}
variable "vpc_name" {
}
variable "app_subnets_name" {
}
variable "app_instance_role_name" {
}

variable "webapp_bucket_name" {
}

variable "force_backend_deployment" {
  type = bool
  default = false
}