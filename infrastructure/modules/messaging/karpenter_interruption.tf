# ==============================================================================
# KARPENTER INTERRUPTION QUEUE & EVENTBRIDGE NOTIFICATION RULES
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SQS Interruption Queue
# Buffers EC2 lifecycle events for Karpenter controller polling
# ------------------------------------------------------------------------------
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "restaurant-api-${var.environment}-karpenter-interruption"
  message_retention_seconds = 300 # 5 minutes retention (Karpenter consumes events rapidly)
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "restaurant-api-${var.environment}-karpenter-interruption"
  }
}

# ------------------------------------------------------------------------------
# 2. SQS Queue Access Policy
# Permits EventBridge (events.amazonaws.com) to publish interruption events
# ------------------------------------------------------------------------------
resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 3. EventBridge Rules & Targets Definition
# Detects EC2 Spot interruptions, AWS Health events,
#   EC2 rebalance recommendations, and EC2 instance state changes, and sends
#   those events to the Karpenter SQS interruption queue.
#   This enables Karpenter to gracefully cordon, drain, and replace Spot nodes.
# ------------------------------------------------------------------------------
locals {
  karpenter_interruption_rules = {
    spot_interruption = {
      name        = "restaurant-api-${var.environment}-karpenter-spot-interruption"
      description = "Catches EC2 Spot Instance 2-minute interruption warning signals"
      event_pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Spot Instance Interruption Warning"]
      })
    }
    rebalance_recommendation = {
      name        = "restaurant-api-${var.environment}-karpenter-rebalance"
      description = "Catches EC2 Instance Rebalance Recommendation signals for proactive draining"
      event_pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance Rebalance Recommendation"]
      })
    }
    scheduled_change = {
      name        = "restaurant-api-${var.environment}-karpenter-scheduled-change"
      description = "Catches AWS Health maintenance events scheduled for underlying hardware"
      event_pattern = jsonencode({
        source      = ["aws.health"]
        detail-type = ["AWS Health Event"]
      })
    }
    instance_state_change = {
      name        = "restaurant-api-${var.environment}-karpenter-state-change"
      description = "Catches EC2 instance state changes (e.g., stopping, terminated)"
      event_pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      })
    }
  }
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = local.karpenter_interruption_rules

  name          = each.value.name
  description   = each.value.description
  event_pattern = each.value.event_pattern

  tags = {
    Name = each.value.name
  }
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each = local.karpenter_interruption_rules

  rule      = aws_cloudwatch_event_rule.karpenter_interruption[each.key].name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}