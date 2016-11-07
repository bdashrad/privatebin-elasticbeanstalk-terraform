# main
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_iam_role" "privatebin" {
  name = "infra-privatebin"
  assume_role_policy = "${file("${path.cwd}/policies/role-ec2.json")}"
}

resource "aws_iam_role_policy" "privatebin" {
  name = "infra-privatebin"
  role = "${aws_iam_role.privatebin.id}"
  policy = "${file("${path.cwd}/policies/policy-elasticbeanstalk-web.json")}"
}

resource "aws_iam_instance_profile" "privatebin" {
  name = "infra-privatebin"
  roles = ["${aws_iam_role.privatebin.name}"]
}

resource "aws_elastic_beanstalk_application" "privatebin" {
  name = "infra-privatebin"
  description = "minimalist, open source online pastebin"
}

resource "aws_elastic_beanstalk_environment" "privatebin-prod" {
  name = "prod"
  application = "${aws_elastic_beanstalk_application.privatebin.name}"
  solution_stack_name = "64bit Amazon Linux 2016.09 v2.2.0 running PHP 7.0"

  # Instance type
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "m1.small"
  }

  # set a key to access the instance
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "${var.ec2_key_name}"
  }

  # use the IAM instance profile we define above to speed up deployments
  setting = {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${aws_iam_instance_profile.privatebin.name}"
  }

  # make it load balanced so we get an ELB
  setting = {
    namespace = "aws:elasticbeanstalk:environment"
    name = "EnvironmentType"
    value = "LoadBalanced"
  }

  # Health
  setting = {
    namespace = "aws:elasticbeanstalk:application"
    name = "Application Healthcheck URL"
    value = "/"
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
    name = "MinSize"
    value = "1"
  }

  setting = {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = "1"
  }

  # Load Balancer settings
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
    value = "arn:aws:iam::${var.aws_account_id}:server-certificate/${var.ssl_cert_id}"
  }

  setting = {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }

}

resource "aws_route53_record" "privatebin" {
  zone_id = "${var.root_zone_id}"
  name = "bin"
  type = "A"
  alias {
    name = "${aws_elastic_beanstalk_environment.privatebin-prod.cname}"
    zone_id = "${lookup(var.aws_eb_zone_id, var.aws_region)}"
    evaluate_target_health = true
  }
}
