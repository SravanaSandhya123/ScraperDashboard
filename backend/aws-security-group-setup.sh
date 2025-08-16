#!/bin/bash
# AWS Security Group Setup for Lavangam Backend
# This script configures security groups for all your backend ports

echo "🔒 Setting up AWS Security Groups for Lavangam Backend..."
echo "📍 IP Address: 18.236.173.88"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    echo "Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI is not authenticated. Please run 'aws configure' first."
    exit 1
fi

echo "🔐 AWS CLI authenticated successfully!"
echo ""

# Get instance information
print_info "Getting instance information..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=ip-address,Values=18.236.173.88" --query 'Reservations[].Instances[].InstanceId' --output text)

if [ -z "$INSTANCE_ID" ]; then
    print_error "Could not find EC2 instance with IP 18.236.173.88"
    print_info "Please make sure the instance is running and the IP is correct."
    exit 1
fi

print_status "Found instance: $INSTANCE_ID"

# Get security group ID
SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text)

if [ -z "$SECURITY_GROUP_ID" ]; then
    print_error "Could not find security group for instance $INSTANCE_ID"
    exit 1
fi

print_status "Found security group: $SECURITY_GROUP_ID"
echo ""

# Define all the ports that need to be opened
PORTS=(
    "80:HTTP"
    "443:HTTPS"
    "8000:Main API"
    "5022:Scrapers API"
    "5024:System Usage API"
    "8004:Dashboard API"
    "5025:Admin Metrics API"
    "8001:Analytics API"
    "8002:Additional Analytics"
    "5020:E-Procurement WebSocket"
    "5021:E-Procurement Server"
    "5023:E-Procurement Fixed"
    "5001:File Manager"
    "5002:Export Server"
    "5005:E-Procurement API"
)

print_info "Configuring security group rules for all ports..."
echo ""

# Add rules for each port
for port_info in "${PORTS[@]}"; do
    IFS=':' read -r port description <<< "$port_info"
    
    print_info "Adding rule for $description (Port $port)..."
    
    # Check if rule already exists
    if aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query "SecurityGroups[].IpPermissions[?FromPort==$port && ToPort==$port]" --output text | grep -q "$port"; then
        print_warning "Rule for port $port already exists, skipping..."
    else
        # Add the rule
        if aws ec2 authorize-security-group-ingress \
            --group-id $SECURITY_GROUP_ID \
            --protocol tcp \
            --port $port \
            --cidr 0.0.0.0/0 &> /dev/null; then
            print_status "Added rule for $description (Port $port)"
        else
            print_error "Failed to add rule for port $port"
        fi
    fi
done

echo ""
print_status "Security group configuration complete!"
echo ""

# Display current security group rules
print_info "Current security group rules:"
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query 'SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp==`0.0.0.0/0`]' --output table

echo ""
print_info "Testing connectivity to key ports..."

# Test key ports
TEST_PORTS=(8000 5022 5024 8004 5025 8001)
for port in "${TEST_PORTS[@]}"; do
    if timeout 5 bash -c "</dev/tcp/18.236.173.88/$port" 2>/dev/null; then
        print_status "Port $port is accessible"
    else
        print_warning "Port $port is not accessible (may still be starting up)"
    fi
done

echo ""
print_status "Security group setup complete!"
echo ""
echo "🌐 Your backend services should now be accessible at:"
echo "   Main API: http://18.236.173.88:8000"
echo "   Scrapers API: http://18.236.173.88:5022"
echo "   System API: http://18.236.173.88:5024"
echo "   Dashboard API: http://18.236.173.88:8004"
echo "   Admin Metrics: http://18.236.173.88:5025"
echo "   Analytics API: http://18.236.173.88:8001"
echo ""
echo "🔒 Security group: $SECURITY_GROUP_ID"
echo "🖥️  Instance: $INSTANCE_ID"
echo "📍 IP Address: 18.236.173.88"
echo ""
echo "💡 Next steps:"
echo "   1. Start your backend services on the EC2 instance"
echo "   2. Test all endpoints from external devices"
echo "   3. Update your frontend to use the new AWS URLs"
