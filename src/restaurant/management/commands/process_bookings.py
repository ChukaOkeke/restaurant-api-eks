import os
import json
import time
import signal
import sys
import boto3
from django.core.management.base import BaseCommand
from django.db import transaction
from dateutil.parser import parse
from restaurant.models import Booking

class Command(BaseCommand):
    help = "Polls SQS queue and processes async booking writes to RDS PostgreSQL."

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.running = True

    def handle(self, *args, **options):
        # Graceful shutdown handling for K8s pod termination
        signal.signal(signal.SIGTERM, self.stop_handler)
        signal.signal(signal.SIGINT, self.stop_handler)

        queue_url = os.getenv('SQS_QUEUE_URL')
        region_name = os.getenv('AWS_REGION', 'eu-west-1')

        if not queue_url:
            self.stderr.write(self.style.ERROR("SQS_QUEUE_URL environment variable is not set."))
            sys.exit(1)

        self.stdout.write(self.style.SUCCESS(f"Starting Worker: Polling {queue_url}..."))
        sqs = boto3.client('sqs', region_name=region_name)

        while self.running:
            try:
                # SQS Long Polling (WaitTimeSeconds=20) to reduce unnecessary API costs
                response = sqs.receive_message(
                    QueueUrl=queue_url,
                    MaxNumberOfMessages=5,
                    WaitTimeSeconds=20,
                    AttributeNames=['All']
                )

                messages = response.get('Messages', [])

                for msg in messages:
                    receipt_handle = msg['ReceiptHandle']
                    body = json.loads(msg['Body'])

                    # Atomic DB operation to guarantee data consistency
                    with transaction.atomic():
                        booking_date = parse(body['booking_date']) if body.get('booking_date') else None
                        
                        Booking.objects.create(
                            name=body['name'],
                            no_of_guests=body['no_of_guests'],
                            booking_date=booking_date
                        )

                    # Delete message from SQS upon successful database insert
                    sqs.delete_message(
                        QueueUrl=queue_url,
                        ReceiptHandle=receipt_handle
                    )
                    self.stdout.write(self.style.SUCCESS(f"Successfully processed booking for: {body.get('name')}"))

            except Exception as e:
                self.stderr.write(self.style.ERROR(f"Error processing SQS message: {str(e)}"))
                time.sleep(2)  # Short delay before retrying polling loop

        self.stdout.write(self.style.SUCCESS("Worker safely stopped."))

    def stop_handler(self, signum, frame):
        self.stdout.write(self.style.WARNING("Received termination signal. Shutting down worker..."))
        self.running = False