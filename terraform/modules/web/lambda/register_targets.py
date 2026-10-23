import os
import boto3

ec2 = boto3.client("ec2")
elb = boto3.client("elbv2")
autoscaling = boto3.client("autoscaling")

TARGET_GROUP_ARN = os.environ["TARGET_GROUP_ARN"]
PORT = 80


def handler(event, context):
    detail = event["detail"]
    instance_id = detail["EC2InstanceId"]
    launching = detail["LifecycleTransition"] == "autoscaling:EC2_INSTANCE_LAUNCHING"
    result = "CONTINUE"

    try:
        reservations = ec2.describe_instances(InstanceIds=[instance_id])["Reservations"]
        ip = reservations[0]["Instances"][0]["PrivateIpAddress"]
        # "all" is required for IPs outside the target group's VPC
        targets = [{"Id": ip, "Port": PORT, "AvailabilityZone": "all"}]

        if launching:
            elb.register_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=targets)
            print(f"Registered {instance_id} ({ip})")
        else:
            elb.deregister_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=targets)
            # let in-flight requests finish before the instance is terminated
            elb.get_waiter("target_deregistered").wait(
                TargetGroupArn=TARGET_GROUP_ARN,
                Targets=targets,
                WaiterConfig={"Delay": 10, "MaxAttempts": 12},
            )
            print(f"Deregistered {instance_id} ({ip})")
    except Exception as e:
        print(f"Failed for {instance_id}: {e}")
        if launching:
            result = "ABANDON"  # ASG terminates it and launches a replacement

    autoscaling.complete_lifecycle_action(
        LifecycleHookName=detail["LifecycleHookName"],
        AutoScalingGroupName=detail["AutoScalingGroupName"],
        LifecycleActionToken=detail["LifecycleActionToken"],
        LifecycleActionResult=result,
    )
