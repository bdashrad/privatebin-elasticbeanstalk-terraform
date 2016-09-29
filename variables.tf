variable "aws_account_id" {
  type = "string"
  description = "aws account id, used to generate some ARNs"
}

variable "aws_eb_zone_id" {
  type = "map"
  description = "aws elasticbeanstalk zone ids"
  default = {
    us-east-1 = "Z117KPS5GTRQ2G"
    us-west-1 = "Z1LQECGX5PH1X"
    us-west-2 = "Z38NKT9BP95V3O"
    ap-south-1 = "Z18NTBI3Y7N9TZ"
    ap-northeast-2 = "Z3JE5OI70TWKCP"
    ap-southeast-1 = "Z16FZ9L249IFLT"
    ap-southeast-2 = "Z2PCDNR3VC2G1N"
    ap-northeast-1 = "Z1R25G3KIG2GBW"
    eu-central-1 = "Z1FRNW7UH4DEZJ"
    eu-west-1 = "Z2NYPWQ7DFZAZH"
    sa-east-1 = "Z10X7K2B4QSOFV"
  }
}

variable "aws_region" {
  type = "string"
  description = "AWS region to host app in"
  default = "us-east-1"
}

variable "ec2_key_name" {
  type = "string"
  description = "name of existing EC2 key pair"
}

variable "root_zone_id" {
  type = "string"
  description = "zone identifier of the route53 zone where the dns record will live"
}

variable "ssl_cert_id" {
  type = "string"
  description = "certificate ID from amazon certificate manager for ELB"
}