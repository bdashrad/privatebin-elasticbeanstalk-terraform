variable "aws_account_id" {
  type = "string"
  description = "aws account id, used to generate some ARNs"
}

variable "aws_region" {
  type = "string"
  description = "AWS region to host app in"
  default = "us-east-1"
}

variable "ssl_cert_id" {
  type = "string"
  description = "certificate ID from amazon certificate manager for ELB"
}

variable "zone_id" {
  type = "string"
  description = "zone identifier of the route53 zone where the dns record will live"
}