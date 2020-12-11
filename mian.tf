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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
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
  sns_topic_arn = aws_cloudformation_stack.sns-topic.outputs["ARN"] # "arn:aws:sns:us-west-1:137959540993:config-s3-complience"

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
  bucket = "config-bucket-for-my-test-project3"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
