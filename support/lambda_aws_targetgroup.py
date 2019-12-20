import json
import boto3


def lambda_handler(event, context):
    ec2client = boto3.client('ec2')
    response = ec2client.describe_instances()
    LBclient = boto3.client('elbv2')
    name_tag = 'lambda tests'
    targetgroup_arn = 'arn:aws:elasticloadbalancing:eu-central-1:746210818476:targetgroup/ranchergroup/4744301a74fb389a'
    
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            for tag in instance["Tags"]:
                if tag.get('Value') == name_tag:
                    if instance["State"].get('Name') == "running":
                        # register the target
                        response = LBclient.register_targets(
                            TargetGroupArn=targetgroup_arn,
                            Targets=[{'Id': instance["InstanceId"]}]
                        )
    return "done"