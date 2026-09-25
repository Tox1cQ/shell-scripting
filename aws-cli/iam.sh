#!/bin/bash

ROLE_NAME="shell-training-lambda-role"
POLICY_NAME="shell-training-policy"
POLICY_ARN="arn:aws:iam::556957333990:policy/$POLICY_NAME"

echo "Starting IAM setup..."
echo

# Create IAM Role
if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
    echo "IAM role already exists: $ROLE_NAME"
else
    echo "Creating IAM role..."

    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://trust-policy.json

    if [ $? -eq 0 ]; then
        echo "IAM role created successfully."
    else
        echo "Failed to create IAM role."
        exit 1
    fi
fi

echo

# Create IAM Policy
if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    echo "IAM policy already exists: $POLICY_NAME"
else
    echo "Creating IAM policy..."

    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://policy-document.json

    if [ $? -eq 0 ]; then
        echo "IAM policy created successfully."
    else
        echo "Failed to create IAM policy."
        exit 1
    fi
fi

echo

# Attach policy to role
echo "Attaching policy to role..."

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

if [ $? -eq 0 ]; then
    echo "Policy attached successfully."
else
    echo "Failed to attach policy."
    exit 1
fi

echo

# Verify Role
echo "Verifying IAM role..."

if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
    echo "Role verification successful."
else
    echo "Role verification failed."
    exit 1
fi

# Verify Policy
echo "Verifying IAM policy..."

if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    echo "Policy verification successful."
else
    echo "Policy verification failed."
    exit 1
fi

echo
echo "IAM setup completed successfully."
