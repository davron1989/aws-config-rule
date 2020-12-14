resource "aws_iam_role" "my-config" {
  name = "config-example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "my-config" {
  role       = "${aws_iam_role.my-config.name}"
  count      = "${length(var.policy_arn)}"
  policy_arn = "${var.policy_arn[count.index]}"
}

resource "aws_config_configuration_recorder" "my-config" {
  name     = "config-example"
  role_arn = "${aws_iam_role.my-config.arn}"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "my-config" {
  name           = "config-example"
  s3_bucket_name = "${aws_s3_bucket.my-config.bucket}"
  sns_topic_arn = aws_cloudformation_stack.sns-topic.outputs["ARN"]

  depends_on = ["aws_config_configuration_recorder.my-config"]
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = "${aws_config_configuration_recorder.my-config.name}"
  is_enabled = true

  depends_on = ["aws_config_delivery_channel.my-config"]
}

resource "aws_config_config_rule" "s3-bucket-server-side-encryption-enabled" {
  name = "s3-bucket-server-side-encryption-enabled"

  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket",
    ]
  }

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.my-config"]
}

resource "aws_s3_bucket" "my-config" {
  bucket = "config-bucket-for-my-test-project4"
  acl    = "private"

  versioning {
    enabled = true
  }

  // lifecycle {
  //   prevent_destroy = true
  // }
}


###################
##SNS TOPIC BLOCK##
###################

## Locals

locals {
  default_tags = {
    "Terraform"        = "true"
    "Terraform-Module" = "deanwilson-sns-email"
  }
}

data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/templates/email-sns-stack.json.tpl")

  vars = {
    display_name  = var.display_name
    email_address = var.email_address
    protocol      = var.protocol
  }
}

resource "aws_cloudformation_stack" "sns-topic" {
  name          = var.stack_name
  template_body = data.template_file.cloudformation_sns_stack.rendered

  // tags = merge(
  //   local.default_tags,
  //   var.additional_tags,
  //   {
  //     "Name" = var.stack_name
  //   },
  // )
}

