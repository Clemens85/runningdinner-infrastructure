#!/bin/bash

QUEUE_URL="http://localhost:4566/000000000000/geocode"
ENDPOINT_URL="http://localhost:4566"

# Poll messages from the SQS queue
aws sqs receive-message --endpoint-url $ENDPOINT_URL --queue-url $QUEUE_URL --max-number-of-messages 10 --wait-time-seconds 60