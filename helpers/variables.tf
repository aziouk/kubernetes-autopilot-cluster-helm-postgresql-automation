# terraform.tfvars

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The region in which to create resources"
  type        = string
}
