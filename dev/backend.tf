terraform {
  backend "s3" {
    bucket = "shared-169411831568-tfstate"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}




aws elbv2 modify-rule \
    --region <region> \
    --rule-arn <rule-arn> \
    --actions '[
        {
            "Type": "forward",
            "ForwardConfig": {
                "TargetGroups": [
                    {
                        "TargetGroupArn": "<backend-target-group-arn>",
                        "Weight": 50
                    },
                    {
                        "TargetGroupArn": "<backend-blue-target-group-arn>",
                        "Weight": 50
                    }
                ]
            }
        }
    ]'