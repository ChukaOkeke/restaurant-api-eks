# This resource creates a service-linked role for AWS Spot Instances. Service-linked roles are predefined by AWS and allow AWS services to perform actions on your behalf. In this case, the role allows the Spot service to manage Spot Instances in your account.

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}