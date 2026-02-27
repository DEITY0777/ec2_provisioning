#!/bin/bash
set -euo pipefail
LOG_FILE="ec2_provision.log"

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$LOG_FILE" >&2
}

check_aws_cli() {
    if ! command -v aws &>/dev/null; then
        echo "AWS CLI not installed. Installing..."

        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        sudo apt-get update -y &>/dev/null
        sudo apt-get install -y unzip &>/dev/null
        unzip -q awscliv2.zip

        sudo ./aws/install
        rm -rf awscliv2.zip aws

        echo "AWS CLI installed successfully"
	log_info "AWS CLI installed successfully"
    fi
}

wait_for_instance() {
    local instance_id="$1"
    echo "Waiting for instance ${instance_id} to reach running state..."
    log_info "Waiting for instance ${instance_id} to reach running state..."

    aws ec2 wait instance-running --instance-ids "$instance_id"

    echo "Instance ${instance_id} is running"
    log_info "Instance ${instance_id} is running"
}

create_ec2_instance() {
    local ami_id="$1"
    local instance_type="$2"
    local key_name="$3"
    local subnet_id="$4"
    local security_group_ids="$5"
    local instance_name="$6"

    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --key-name "$key_name" \
        --subnet-id "$subnet_id" \
        --security-group-ids "$security_group_ids" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )

    if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
        echo "Failed to create EC2 instance"
	log_error "Failed to create EC2 instance"
        exit 1
    fi

    echo "Instance $instance_id created successfully"
    log_info "Instance $instance_id created successfully"

    wait_for_instance "$instance_id"
}

check_existing_instance() {
    local instance_name="$1"

    existing_instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${instance_name}" \
                  "Name=instance-state-name,Values=pending,running,stopping,stopped" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text)

    if [[ -n "$existing_instance_id" && "$existing_instance_id" != "None" ]]; then
        echo "Instance with name '${instance_name}' already exists: $existing_instance_id"
        echo "Aborting to prevent duplicate instance creation."
	log_error "Instance with name '${instance_name}' already exists: $existing_instance_id"
        exit 1
    fi
}

main() {
    check_aws_cli

    echo "Creating EC2 instance..."


    AMI_ID="ami-019715e0d74f695be"
    INSTANCE_TYPE="t3.micro"
    KEY_NAME="kub.key"
    SUBNET_ID="subnet-08d6155409d840676"
    SECURITY_GROUP_IDS="sg-0398e68aa763996ad"
    INSTANCE_NAME="shell_instance"
    
    check_existing_instance "$INSTANCE_NAME"    
    create_ec2_instance "$AMI_ID" "$INSTANCE_TYPE" "$KEY_NAME" "$SUBNET_ID" "$SECURITY_GROUP_IDS" "$INSTANCE_NAME"

    echo "EC2 instance creation completed"
    log_info "EC2 instance creation completed"
}

main "$@"
