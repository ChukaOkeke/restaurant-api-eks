# ==============================================================================
# Module Outputs
# ==============================================================================

output "booking_queue_arn" {
  description = "ARN of the primary SQS booking queue"
  value       = aws_sqs_queue.booking_queue.arn
}

output "booking_queue_url" {
  description = "URL endpoint for Django API and worker pods to produce/consume SQS messages"
  value       = aws_sqs_queue.booking_queue.id
}

output "booking_queue_name" {
  description = "Name of the primary SQS booking queue"
  value       = aws_sqs_queue.booking_queue.name
}

output "booking_dlq_arn" {
  description = "ARN of the SQS Dead Letter Queue"
  value       = aws_sqs_queue.booking_dlq.arn
}

output "booking_dlq_url" {
  description = "URL endpoint of the SQS Dead Letter Queue"
  value       = aws_sqs_queue.booking_dlq.id
}