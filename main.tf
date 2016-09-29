# main
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_elastic_beanstalk_application" "privatebin" {
  name = "privatebin"
  description = "minimalist, open source online pastebin"
}

resource "aws_elastic_beanstalk_environment" "privatebin-prod" {
  name = "prod"
  application = "${aws_elastic_beanstalk_application.privatebin.name}"
  solution_stack_name = "64bit Amazon Linux 2016.03 v2.1.6 running PHP 7.0"

  # Instance type
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "m3.medium"
  }

  # Load Balancing
  setting = {
    namespace = "aws:elb:listener:443"
    name = "ListenerProtocol"
    value = "HTTPS"
  }

  setting = {
    namespace = "aws:elb:listener:443"
    name = "InstancePort"
    value = "80"
  }

  setting = {
    namespace = "aws:elb:listener:443"
    name = "SSLCertificateId"
    value = "arn:aws:acm:${var.aws_region}:${var.aws_account_id}:certificate/${var.ssl_cert_id}"
  }

  setting = {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }

  setting = {
    namespace = "aws:elb:policies"
    name = "ConnectionDrainingEnabled"
    value = "true"
  }

}

resource "aws_route53_record" "privatebin" {
  zone_id = "${var.zone_id}"
  name = "bin"
  type = "CNAME"
  ttl = "60"
  records = ["aws_elastic_beanstalk_environment.privatebin-prod.cname"]
}

