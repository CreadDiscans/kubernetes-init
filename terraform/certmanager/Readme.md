# aws route53 dns01 인증을 위한 권한

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZones",
                "route53:ListHostedZonesByName",
                "route53:GetChange"
            ],
            "Resource": "*"
        }
    ]
}