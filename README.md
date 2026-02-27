EC2 Provisioning Automation Script

A Bash script to automate the creation of an AWS EC2 instance using AWS CLI.
This project demonstrates basic infrastructure automation with validation, idempotency checks, and logging.

Features:

- Checks and installs AWS CLI if missing

- Validates AWS credentials

- Prevents duplicate instance creation (based on Name tag)

- Waits until instance reaches running state

- Logs all major operations to a log file

- Uses safe Bash practices (set -euo pipefail)

Requirements:

- Linux (Tested on Ubuntu EC2)

- AWS account

- Configured AWS credentials (aws configure)

Required:

- AMI ID

- Key Pair

- Subnet ID

- Security Group ID

Run the script:

./ec2_provision.sh

(You can modify the configuration values inside the script.)
