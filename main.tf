resource "aws_ecs_service" "service" {
  name            = "${var.name}"
  cluster         = "${var.cluster}"
  task_definition = "${var.task_definition}"
  desired_count   = "${var.desired_count}"
  iam_role        = "${aws_iam_role.role.arn}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}


resource "aws_alb_target_group" "target_group" {
  name                 = "${var.name}"

  # port will be set dynamically, but for some reason AWS requires a value
  port                 = "31337"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    matcher             = "${var.health_check_matcher}"
  }
}


resource "aws_iam_role" "role" {
  name_prefix        = "${var.name}-service-role"

  # from http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_IAM_role.html
  assume_role_policy = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ecs.amazonaws.com" },
      "Effect": "Allow"
    }
  ]
}
END
}


resource "aws_iam_role_policy" "policy" {
  role        = "${aws_iam_role.role.id}"
  name_prefix = "${var.name}-service-policy"

  # from http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_IAM_role.html (step 7)
  policy      = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
END
}