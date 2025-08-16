# Clean LAVANGAM Backend EC2 Deployment Script
# This script will deploy your backend with all required ports

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyName = "lavangam-key",
    [string]$SecurityGroupName = "lavangam-backend-sg",
    [string]$InstanceName = "lavangam-backend-server"
)

Write-Host "🚀 Starting LAVANGAM Backend EC2 Deployment..." -ForegroundColor Green
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

# Create security group with ALL your ports
Write-Host "`n🔒 Creating security group with ALL required ports..." -ForegroundColor Yellow
try {
    $sgExists = aws ec2 describe-security-groups --group-names $SecurityGroupName 2>$null
    if ($sgExists) {
        Write-Host "✅ Security group '$SecurityGroupName' already exists" -ForegroundColor Green
        $sgId = aws ec2 describe-security-groups --group-names $SecurityGroupName --query 'SecurityGroups[0].GroupId' --output text
    } else {
        $sgId = aws ec2 create-security-group --group-name $SecurityGroupName --description "LAVANGAM Backend Security Group - All Ports" --query 'GroupId' --output text
        Write-Host "✅ Security group created: $sgId" -ForegroundColor Green
        
        # Add ALL your required ports
        $ports = @(22, 80, 443, 8000, 5022, 5024, 8004, 5025, 8001, 8002, 5020, 5021, 5023, 5001, 5002, 5005, 3306)
        
        foreach ($port in $ports) {
            aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port $port --cidr 0.0.0.0/0
            Write-Host "   ✅ Port $port opened" -ForegroundColor Green
        }
        
        Write-Host "✅ All $($ports.Count) ports configured in security group" -ForegroundColor Green
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
        
        # Fix permissions on Windows
        try {
            $acl = Get-Acl "$KeyName.pem"
            $acl.SetAccessRuleProtection($true, $false)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl "$KeyName.pem" $acl
            Write-Host "✅ Key pair permissions fixed for Windows" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Warning: Could not fix key permissions automatically" -ForegroundColor Yellow
        }
        
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
    $instance = aws ec2 run-instances --image-id $amiId --count 1 --instance-type $InstanceType --key-name $KeyName --security-group-ids $sgId --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName},{Key=Project,Value=LAVANGAM Backend},{Key=Environment,Value=Production}]" --query 'Instances[0]' --output json | ConvertFrom-Json
    
    $instanceId = $instance.InstanceId
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    Write-Host "⏳ Waiting for instance to be running..." -ForegroundColor Yellow
    
    # Wait for instance to be running
    do {
        Start-Sleep -Seconds 10
        $status = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].State.Name' --output text
        Write-Host "   Instance status: $status" -ForegroundColor Cyan
    } while ($status -ne "running")
    
    Write-Host "✅ Instance is now running!" -ForegroundColor Green
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    Write-Host "✅ Public IP: $publicIp" -ForegroundColor Green
    
    # Save deployment info
    $deploymentInfo = @{
        InstanceId = $instanceId
        PublicIP = $publicIp
        InstanceType = $InstanceType
        KeyName = $KeyName
        SecurityGroupId = $sgId
        LaunchTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Status = "Deployed"
    }
    
    $deploymentInfo | ConvertTo-Json | Out-File "deployment-info.json" -Encoding UTF8
    Write-Host "✅ Deployment information saved to: deployment-info.json" -ForegroundColor Green
    
    # Display next steps
    Write-Host "`n🎉 EC2 Instance Deployed Successfully!" -ForegroundColor Green
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor White
    Write-Host "Public IP: $publicIp" -ForegroundColor White
    Write-Host "Instance Type: $InstanceType" -ForegroundColor White
    Write-Host "SSH Access: ssh -i $KeyName.pem ubuntu@$publicIp" -ForegroundColor White
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Wait 2-3 minutes for instance to fully initialize" -ForegroundColor White
    Write-Host "2. Test SSH connection: ssh -i $KeyName.pem ubuntu@$publicIp" -ForegroundColor White
    Write-Host "3. Upload setup script: scp -i $KeyName.pem setup-backend-on-ec2-enhanced.sh ubuntu@$publicIp" -ForegroundColor White
    Write-Host "4. Run setup script on EC2 instance" -ForegroundColor White
    Write-Host "5. Upload your backend code" -ForegroundColor White
    
    Write-Host "`n🔒 Security Group Ports Open:" -ForegroundColor Yellow
    Write-Host "SSH (22), HTTP (80), HTTPS (443), MySQL (3306)" -ForegroundColor White
    Write-Host "Main API (8000), Scrapers (5022), System (5024), Dashboard (8004)" -ForegroundColor White
    Write-Host "Admin (5025), Analytics (8001, 8002), E-Procurement (5020, 5021, 5023)" -ForegroundColor White
    Write-Host "File Manager (5001), Export (5002), E-Proc API (5005)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to launch EC2 instance: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n🚀 Deployment completed successfully!" -ForegroundColor Green
