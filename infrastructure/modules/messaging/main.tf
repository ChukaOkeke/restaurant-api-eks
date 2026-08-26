# =========================================================================
#                 ASYNCHRONOUS DECOUPLING WITH SQS
# =========================================================================

# ==============================================================================
# Dead Letter Queue (DLQ)
# ==============================================================================
# Holds booking messages that fail processing after maximum retry attempts.
# Prevents poison messages from blocking the primary intake pipeline.
resource "aws_sqs_queue" "booking_dlq" {
  name                      = "restaurant-api-${var.environment}-booking-dlq"
  message_retention_seconds = var.dlq_retention_seconds # 14-day retention for inspection & manual reprocessing
  sqs_managed_sse_enabled   = true                      # Server-Side Encryption using AWS-managed key

  # checkov:skip=CKV2_AWS_73:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient

  # Restrict tags exclusively to Name; provider default_tags handle environment/project
  tags = {
    Name = "restaurant-api-${var.environment}-booking-dlq"
  }
}

# ==============================================================================
# Primary Booking SQS Queue
# ==============================================================================
# Decouples the Django API (intake layer) from worker pods (RDS write layer).
# Enables immediate HTTP 202 Accepted responses to incoming web traffic.
resource "aws_sqs_queue" "booking_queue" {
  name                       = "restaurant-api-${var.environment}-booking-queue"
  delay_seconds              = var.queue_delay_seconds        # 0: No delay; process messages immediately
  max_message_size           = var.max_message_size           # 256 KB payload cap
  message_retention_seconds  = var.queue_retention_seconds    # 4-day retention window
  receive_wait_time_seconds  = var.receive_wait_time_seconds  # Long polling (20s) to minimize empty API calls & AWS cost
  visibility_timeout_seconds = var.visibility_timeout_seconds # Processing window reserved for a worker pod before retry
  sqs_managed_sse_enabled    = true                           # Server-Side Encryption using AWS-managed key

  # Redrive Policy: Automatically routes unacknowledged messages to DLQ after 3 failures
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.booking_dlq.arn
    maxReceiveCount     = var.max_receive_count # Max retries before dropping to DLQ
  })

  # checkov:skip=CKV2_AWS_73:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient

  tags = {
    Name = "restaurant-api-${var.environment}-booking-queue"
  }
}

# ==============================================================================
# DLQ Redrive Allow Policy
# ==============================================================================
# Enforces Security Principle of Least Privilege: only the primary booking queue
# is authorized to route failed messages to this DLQ instance.
resource "aws_sqs_queue_redrive_allow_policy" "booking_dlq" {
  queue_url = aws_sqs_queue.booking_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.booking_queue.arn]
  })
}