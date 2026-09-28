
#!/bin/bash

set -Eeuo pipefail

# Configuration
AWS_REGION="ap-south-1"
ACCOUNT_ID=""
RUN_ID="$(date +%Y%m%d%H%M%S)-$$"
BUCKET_NAME=""
TABLE_NAME="shell-training-${RUN_ID}"
TEST_FILE="/tmp/s3-test-${RUN_ID}.txt"
S3_KEY="test-${RUN_ID}.txt"
BUCKET_CREATED=false
TABLE_CREATED=false

# Cleanup resources created by this script
cleanup() {
    local exit_code=$?
    trap - EXIT
    set +e

    echo
    echo "Starting cleanup..."

    if [[ "$BUCKET_CREATED" == true ]]; then
        echo "Removing S3 test objects..."
        if aws s3 rm "s3://${BUCKET_NAME}" --recursive --region "$AWS_REGION"; then
            echo "Deleting S3 test bucket..."
            if aws s3api delete-bucket \
                --bucket "$BUCKET_NAME" \
                --region "$AWS_REGION"; then
                echo "S3 bucket deleted successfully."
            else
                echo "Warning: Could not delete S3 bucket: $BUCKET_NAME"
                exit_code=1
            fi
        else
            echo "Warning: Could not remove S3 objects from $BUCKET_NAME"
            exit_code=1
        fi
    fi

    if [[ "$TABLE_CREATED" == true ]]; then
        echo "Deleting DynamoDB test table..."
        if aws dynamodb delete-table \
            --table-name "$TABLE_NAME" \
            --region "$AWS_REGION" >/dev/null; then
            if aws dynamodb wait table-not-exists \
                --table-name "$TABLE_NAME" \
                --region "$AWS_REGION"; then
                echo "DynamoDB table deleted successfully."
            else
                echo "Warning: Could not confirm DynamoDB table deletion."
                exit_code=1
            fi
        else
            echo "Warning: Could not delete DynamoDB table: $TABLE_NAME"
            exit_code=1
        fi
    fi

    rm -f "$TEST_FILE"
    echo "Local test file removed."

    if [[ $exit_code -eq 0 ]]; then
        echo "Cleanup completed successfully."
    else
        echo "Cleanup completed with errors. Check AWS resources manually."
    fi

    exit "$exit_code"
}

# Check AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    echo "Error: AWS CLI is not installed."
    exit 1
fi

echo "AWS CLI version:"
aws --version

# Check AWS configuration
echo
echo "Checking AWS CLI configuration..."
aws configure list

# Check AWS authentication
if ! IDENTITY=$(aws sts get-caller-identity \
    --region "$AWS_REGION" \
    --output json 2>/dev/null); then
    echo "Error: AWS authentication failed."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity \
    --query Account \
    --output text \
    --region "$AWS_REGION")

BUCKET_NAME="tushar-shell-automation-${ACCOUNT_ID}-${RUN_ID}"

echo "AWS authentication successful."
echo "$IDENTITY"

# Register cleanup after AWS CLI and authentication checks
trap cleanup EXIT

# S3 operations
echo
echo "Creating S3 bucket: $BUCKET_NAME"

if aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null; then
    BUCKET_CREATED=true
    echo "S3 bucket created successfully."
else
    echo "Error: Failed to create S3 bucket."
    exit 1
fi

echo "Creating test file..."
printf 'Hello from AWS shell automation!\n' > "$TEST_FILE"

echo "Uploading test file to S3..."
aws s3 cp "$TEST_FILE" "s3://${BUCKET_NAME}/${S3_KEY}" --region "$AWS_REGION"
echo "File uploaded successfully."

echo
echo "Listing S3 bucket contents..."
aws s3 ls "s3://${BUCKET_NAME}/" --region "$AWS_REGION"
echo "S3 listing completed successfully."

# DynamoDB operations
echo
echo "Creating DynamoDB table: $TABLE_NAME"

if aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=record_id,AttributeType=S \
    --key-schema AttributeName=record_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" >/dev/null; then
    TABLE_CREATED=true
    echo "DynamoDB table creation requested."
else
    echo "Error: Failed to create DynamoDB table."
    exit 1
fi

echo "Waiting for DynamoDB table to become active..."
aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$AWS_REGION"
echo "DynamoDB table is active."

echo
echo "Inserting test record..."
aws dynamodb put-item \
    --table-name "$TABLE_NAME" \
    --item '{
        "record_id": {"S": "record-001"},
        "message": {"S": "Hello from AWS automation"},
        "environment": {"S": "EC2"}
    }' \
    --region "$AWS_REGION"
echo "Test record inserted successfully."

echo
echo "Reading test record..."
RECORD=$(aws dynamodb get-item \
    --table-name "$TABLE_NAME" \
    --key '{"record_id":{"S":"record-001"}}' \
    --consistent-read \
    --region "$AWS_REGION" \
    --output json)

echo "Retrieved DynamoDB record:"
echo "$RECORD"

echo
echo "All AWS operations completed successfully."
  
