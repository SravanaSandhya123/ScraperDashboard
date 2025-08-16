# Simple AWS EC2 Deployment for Lavangam Backend
# This script creates the EC2 instance and provides setup instructions

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyName = "lavangam-key",
    [string]$SecurityGroupName = "lavangam-backend-sg",
    [string]$InstanceName = "lavangam-backend-server"
)

Write-Host "🚀 Starting Lavangam Backend AWS EC2 Deployment..." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan

# Check AWS CLI installation
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
    } else {
        throw "AWS CLI not found"
    }
} catch {
    Write-Host "❌ AWS CLI not found or not in PATH!" -ForegroundColor Red
    Write-Host "Please install AWS CLI and configure your credentials first." -ForegroundColor Yellow
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Cyan
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    Write-Host "✅ AWS credentials configured for account: $($identity.Account)" -ForegroundColor Green
    Write-Host "   User: $($identity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ AWS credentials not configured!" -ForegroundColor Red
    Write-Host "Please run 'aws configure' to set up your credentials." -ForegroundColor Yellow
    exit 1
}

# Create security group
Write-Host "`n🔒 Creating security group..." -ForegroundColor Yellow
try {
    $sgExists = aws ec2 describe-security-groups --group-names $SecurityGroupName 2>$null
    if ($sgExists) {
        Write-Host "✅ Security group '$SecurityGroupName' already exists" -ForegroundColor Green
    } else {
        $sgId = aws ec2 create-security-group --group-name $SecurityGroupName --description "Lavangam Backend Security Group" --query 'GroupId' --output text
        Write-Host "✅ Security group created: $sgId" -ForegroundColor Green
        
        # Add security group rules
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8000 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8080 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 3306 --cidr 0.0.0.0/0
        
        Write-Host "✅ Security group rules configured" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to create security group: $_" -ForegroundColor Red
    exit 1
}

# Create key pair
Write-Host "`n🔑 Creating key pair..." -ForegroundColor Yellow
try {
    $keyExists = aws ec2 describe-key-pairs --key-names $KeyName 2>$null
    if ($keyExists) {
        Write-Host "✅ Key pair '$KeyName' already exists" -ForegroundColor Green
    } else {
        aws ec2 create-key-pair --key-name $KeyName --query 'KeyMaterial' --output text > "$KeyName.pem"
        Write-Host "✅ Key pair created and saved to $KeyName.pem" -ForegroundColor Green
        Write-Host "⚠️  IMPORTANT: Keep this .pem file secure!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to create key pair: $_" -ForegroundColor Red
    exit 1
}

# Get the latest Ubuntu 22.04 LTS AMI
Write-Host "`n🔍 Getting latest Ubuntu 22.04 LTS AMI..." -ForegroundColor Yellow
try {
    $amiId = aws ssm get-parameters --names "/aws/service/canonical/ubuntu/server/22.04/latest/amd64/hvm/ebs-gp2/ami-id" --query 'Parameters[0].Value' --output text
    Write-Host "✅ Using AMI: $amiId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get AMI: $_" -ForegroundColor Red
    exit 1
}

# Launch EC2 instance
Write-Host "`n🚀 Launching EC2 instance..." -ForegroundColor Yellow
try {
    $instance = aws ec2 run-instances --image-id $amiId --count 1 --instance-type $InstanceType --key-name $KeyName --security-group-ids $SecurityGroupName --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName},{Key=Project,Value=Lavangam Backend},{Key=Environment,Value=Production}]" --query 'Instances[0]' --output json | ConvertFrom-Json
    
    $instanceId = $instance.InstanceId
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    Write-Host "⏳ Waiting for instance to be running..." -ForegroundColor Yellow
    
    # Wait for instance to be running
    do {
        Start-Sleep -Seconds 10
        $status = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].State.Name' --output text
        Write-Host "   Instance status: $status" -ForegroundColor Cyan
    } while ($status -ne "running")
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "`n🎉 EC2 Instance Created Successfully!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor White
    Write-Host "Public IP: $publicIp" -ForegroundColor White
    Write-Host "Instance Type: $InstanceType" -ForegroundColor White
    
    Write-Host "`n🔐 SSH Access:" -ForegroundColor Yellow
    Write-Host "ssh -i $KeyName.pem ubuntu@$publicIp" -ForegroundColor White
    
    # Save deployment info
    $deploymentInfo = @{
        InstanceId = $instanceId
        PublicIP = $publicIp
        InstanceType = $InstanceType
        DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "EC2 Created - Ready for Setup"
        SSHCommand = "ssh -i $KeyName.pem ubuntu@$publicIp"
    }
    
    $deploymentInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath "deployment-info.json" -Encoding UTF8
    Write-Host "`n💾 Deployment information saved to: deployment-info.json" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to launch EC2 instance: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. SSH into your EC2 instance using the command above" -ForegroundColor White
Write-Host "2. Run the setup script: bash <(curl -s https://raw.githubusercontent.com/your-repo/setup.sh)" -ForegroundColor White
Write-Host "3. Or copy the setup script from your local machine" -ForegroundColor White
Write-Host "4. Wait for setup to complete (5-10 minutes)" -ForegroundColor White
Write-Host "5. Test your backend endpoints" -ForegroundColor White

Write-Host "`n✅ EC2 instance deployment completed successfully!" -ForegroundColor Green
Write-Host "Your Lavangam backend EC2 instance is now ready for setup." -ForegroundColor Cyan
