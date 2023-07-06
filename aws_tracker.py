import os
import boto3
import requests
import json
from tabulate import tabulate


def main(event, context):
    ec2 = boto3.client("ec2")
    regions = ec2.describe_regions()

    table_data = []

    for region in regions["Regions"]:
        ec2_region = boto3.client("ec2", region_name=region["RegionName"])
        response = ec2_region.describe_instances()

        for reservation in response["Reservations"]:
            for instance in reservation["Instances"]:
                instance_name = get_tag_value(instance, "Name")
                instance_type = instance["InstanceType"]
                instance_state = instance["State"]["Name"]
                customer_tag = get_tag_value(instance, "Customer")

                table_data.append(
                    [
                        instance_name,
                        region["RegionName"],
                        instance_type,
                        instance_state,
                        customer_tag,
                    ]
                )

    # Convert data into tabular format and send as a slack message
    table_string = tabulate(
        table_data,
        headers=["Name", "Region", "Size", "State", "Customer Tag"],
        tablefmt="pipe",
    )
    send_slack_message(table_string)


def get_tag_value(instance, tag_key):
    """Helper function to extract a tag value from instance"""
    tags = instance.get("Tags", [])
    for tag in tags:
        if tag["Key"] == tag_key:
            return tag["Value"]
    return ""  # return empty string if no such tag


def send_slack_message(message):
    slack_webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    slack_message = {
        "channel": "#aws-notifications",
        "blocks": [
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": "```\n" + message + "\n```"},
            }
        ],
    }

    requests.post(
        slack_webhook_url,
        data=json.dumps(slack_message),
        headers={"Content-Type": "application/json"},
    )
