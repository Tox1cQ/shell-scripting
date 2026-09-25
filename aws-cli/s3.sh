#!/bin/bash

BUCKET_NAME="tushar-shell-training-2026"
AWS_REGION="ap-south-1"
TEST_FILE="s3-test.txt"

echo "Starting S3 setup..."
echo

echo "Checking AWS CLI..."

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS CLI authentication failed."
    exit 1
fi

echo "AWS CLI authentication successful."
echo

echo "Creating test file..."

echo "Hello from AWS CLI Shell Scripting" > "$TEST_FILE"

if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Failed to create test file."
    exit 1
fi

echo "Test file created successfully."
echo

echo "Checking S3 bucket..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "S3 bucket already exists: $BUCKET_NAME"
else
    echo "Creating S3 bucket..."

    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"

    if [ $? -eq 0 ]; then
        echo "S3 bucket created successfully."
    else
        echo "Error: Failed to create S3 bucket."
        exit 1
    fi
fi

echo

echo "Uploading test file..."

aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/"

if [ $? -eq 0 ]; then
    echo "File uploaded successfully."
else
    echo "Error: File upload failed."
    exit 1
fi

echo

echo "Listing bucket contents..."

aws s3 ls "s3://$BUCKET_NAME/"

if [ $? -eq 0 ]; then
    echo
    echo "S3 operation completed successfully."
else
    echo "Error: Failed to list bucket contents."
    exit 1
fi
