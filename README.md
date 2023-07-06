# AWS instances tracker
This is a simple internal script we wrote to make sure we turn off and delete AWS instances once done.

This script is currently configured to send a notification every Thursday afternoon.

## Setup
1. Install terraform: `terraform init`
2. Create a vars file with your [Slack webhook token](https://api.slack.com/messaging/webhooks). See example.tfvars.
3. Build a deployment package: `./build.sh`
4. Deploy to your AWS account: `terraform apply -var-file=<your-var-file-here.tfvars>`

## Contributing
Feel free to PR, copy, or use this code in any way you feel like. 

