# input variables
variable "aws_region" {
  type        = "string"
  description = "AWS region to host app in"
  default     = "us-east-1"
}

variable "dns_name" {
  type        = "string"
  description = "DNS record name for PasteBin. e.g. `dns_name.example.com`"
  default     = "privatebin"
}

variable "dns_zone" {
  type        = "string"
  description = "Route53 zone name where the dns record will live."
}

variable "ec2_key_name" {
  type        = "string"
  description = "Name of existing EC2 key pair"
}

variable "instance_type" {
  type        = "string"
  description = "Instance size to use for elasticbeanstalk"
  default     = "m1.small"
}

variable "private_zone" {
  type        = "string"
  description = "Use private route53 zone"
  default     = "false"
}

variable "ssl_cert_arn" {
  type        = "string"
  description = "ARN for IAM or ACM certificate for ELB"
}

# providers
provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {}

data "aws_elastic_beanstalk_hosted_zone" "current" {}

data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}"
  private_zone = "${var.private_zone}"
}

# resources
## IAM
data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "privatebin" {
  name               = "${var.dns_name}-privatebin"
  assume_role_policy = "${data.aws_iam_policy_document.ec2.json}"
}

resource "aws_iam_role_policy_attachment" "privatebin" {
  role       = "${aws_iam_role.privatebin.id}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "privatebin" {
  name = "${var.dns_name}-privatebin"
  role = "${aws_iam_role.privatebin.name}"
}

resource "aws_elastic_beanstalk_application" "privatebin" {
  name        = "${var.dns_name}-privatebin"
  description = "minimalist, open source online pastebin"
}

resource "aws_elastic_beanstalk_environment" "privatebin" {
  name                = "${var.dns_name}"
  application         = "${aws_elastic_beanstalk_application.privatebin.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.9 running PHP 7.2"

  # Instance type
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${var.instance_type}"
  }

  # set a key to access the instance
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${var.ec2_key_name}"
  }

  # use the IAM instance profile we define above to speed up deployments
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${aws_iam_instance_profile.privatebin.name}"
  }

  # make it load balanced so we get an ELB
  setting = {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Health
  setting = {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/"
  }

  # setting = {
  #   namespace = "aws:elasticbeanstalk:healthreporting:system"
  #   name = "SystemType"
  #   value = "enhanced"
  # }


  # setting = {
  #   namespace = "aws:elasticbeanstalk:healthreporting:system"
  #   name = "ConfigDocument"
  #   value = "${file("${path.cwd}/policies/config-ebhealthreporting.json")}"
  # }

  # we don't need to scale
  setting = {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  setting = {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
  # Load Balancer settings
  setting = {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }
  setting = {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "80"
  }
  setting = {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "${var.ssl_cert_arn}"
  }
  setting = {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }
  setting = {
    namespace = "aws:elb:policies:sslpolicy"
    name      = "SSLReferencePolicy"
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }
  setting = {
    namespace = "aws:elb:policies:sslpolicy"
    name      = "LoadBalancerPorts"
    value     = "443"
  }
}

resource "aws_route53_record" "privatebin" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_elastic_beanstalk_environment.privatebin.cname}"
    zone_id                = "${data.aws_elastic_beanstalk_hosted_zone.current.id}"
    evaluate_target_health = true
  }
}
