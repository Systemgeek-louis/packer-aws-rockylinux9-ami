Policy: AllowUseofKMS
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowUseofKMS",
            "Effect": "Allow",
            "Action": [
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*"
            ],
            "Resource": "*"
        }
    ]
}
Policy: PackerIAMPassRole
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PackerIAMPassRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:GetInstanceProfile"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
Policy: Packer-EC2_AMI-Build
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
