# ============================================================================
# AWS Cloud Network Infrastructure - Module 00 Deployment Script
# Purpose: Automate module 00 setup and GitHub deployment
# ============================================================================

param(
    [string]$RepoPath = ".",
    [string]$GitBranch = "main",
    [string]$CommitMessage = "Add Module 00: Complete AWS Traffic Flow",
    [switch]$AutoPush = $false
)

# Color output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

Write-Info "╔════════════════════════════════════════════════════════════════╗"
Write-Info "║     Module 00 Deployment Script - AWS Traffic Flow            ║"
Write-Info "╚════════════════════════════════════════════════════════════════╝"
Write-Info ""

# Step 1: Verify repo exists
Write-Info "STEP 1: Verifying repository..."
if (-not (Test-Path "$RepoPath/.git")) {
    Write-Error "❌ .git directory not found at $RepoPath"
    Write-Info "Please run this script from the root of your repository:"
    Write-Info "  cd C:\path\to\enterprise-aws-cloud-network-infrastructure"
    exit 1
}
Write-Success "✓ Repository found"

# Step 2: Check existing module structure
Write-Info ""
Write-Info "STEP 2: Checking module structure..."
$moduleDir = "$RepoPath/00-aws-traffic-flow"

if (Test-Path $moduleDir) {
    Write-Warning "⚠ Module directory already exists: $moduleDir"
    $confirm = Read-Host "Overwrite? (y/n)"
    if ($confirm -ne 'y') {
        Write-Error "Aborted."
        exit 1
    }
    Write-Info "Removing existing module directory..."
    Remove-Item $moduleDir -Recurse -Force
}

# Step 3: Create module directory structure
Write-Info ""
Write-Info "STEP 3: Creating module directory structure..."
$directories = @(
    "$moduleDir",
    "$moduleDir/diagrams"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "✓ Created: $dir"
    }
}

# Step 4: Download/create files
Write-Info ""
Write-Info "STEP 4: Setting up module files..."

# 4a: README.md (Refactored)
Write-Info "→ Creating README.md..."
$readmeContent = @"
# 0 — Complete AWS Traffic Flow

![Architecture Diagram](./architecture-diagram.svg)

## Overview

A production request traveling to your application doesn't take a direct path. It passes through **11+ networking layers**, each performing critical functions: DNS resolution, global caching, security filtering, load balancing, routing, access control, and database connectivity.

### Why This Matters

When something breaks—application unreachable, database timeout, slow response—you won't know which layer to investigate without understanding the complete flow. A methodical troubleshooting approach—tracing the request path step by step—reveals the issue 90% of the time. This module maps the complete journey of a production request, showing what happens at each layer, common failure points, and how to debug the entire chain.

## Core Components

| Layer | Component | Purpose | Failure Impact |
|-------|-----------|---------|-----------------|
| **1** | Route 53 | DNS resolution | Domain unreachable |
| **2** | CloudFront + WAF | CDN + security filtering | Slow/blocked access |
| **3** | ALB | Load balancing + TLS termination | Requests fail to route |
| **4** | VPC + Route Tables | Network routing decisions | Traffic lost/misrouted |
| **5** | Security Groups | Stateful access control | Connections refused |
| **6** | App Servers | Business logic processing | Application errors |
| **7** | RDS Database | Data persistence | Queries timeout |
| **8** | NAT Gateway | Egress control for private subnets | Outbound blocked |
| **9** | NACLs | Subnet-level stateless rules | Port filtering at subnet level |
| **10** | ENIs | Attachment points for instances | Network interface issues |
| **11** | Elastic IPs | Static public addressing | IP routing issues |

## Build Steps

Follow this flow for a production request to \`https://app.example.com/api/data\`:

1. **DNS Resolution (Route 53)** — Browser resolves domain name to IP address; Route 53 checks endpoint health and returns the appropriate IP (CloudFront edge location).

2. **CloudFront Edge Connection** — Request hits the nearest CDN edge; CloudFront checks cache (static content, images), applies WAF rules (rate limiting, DDoS protection, geo-blocking), and forwards to origin if not cached.

3. **TLS Termination (ALB)** — Application Load Balancer accepts HTTPS connection, terminates TLS/SSL, and verifies certificate validity.

4. **VPC Routing** — Request crosses VPC boundary; route tables determine whether traffic stays local (10.0.0.0/16 → Local) or exits through internet gateway.

5. **ALB Security Group** — Stateful firewall allows inbound TCP 80/443 from 0.0.0.0/0; stateful behavior auto-allows response traffic.

6. **Target Group Selection** — ALB evaluates listener rules (host-based, path-based) and selects appropriate target group; performs health checks every 30 seconds.

7. **App Server Security Group** — Stateful firewall allows inbound only from ALB (source: ALB security group); may allow outbound to database and external APIs.

8. **Application Processing** — App server receives HTTP request on port 8080 (or configured port); processes business logic, queries database, calls external services.

9. **Database Access (RDS)** — App initiates connection to RDS on port 3306 (MySQL) or 5432 (PostgreSQL); RDS security group must allow source (app security group).

10. **Egress Control (NAT Gateway)** — When app needs internet access, private instance routes through NAT Gateway in public subnet; private IP translates to NAT's Elastic IP.

11. **Response Path (Reverse)** — Response travels back through ALB → CloudFront → user; CloudFront caches response based on Cache-Control headers.

## Lessons Learned

### Scenario 1: "Connection Timeout" — Users Can't Reach Application

\`\`\`bash
# Step 1: DNS works?
nslookup app.example.com

# Step 2: Is CloudFront reachable?
curl -I https://203.0.113.1

# Step 3: Check ALB targets healthy
aws elbv2 describe-target-health --target-group-arn \$TG_ARN

# Step 4: Check target security group
aws ec2 describe-security-groups --group-ids sg-app

# Fix: Add inbound rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-app \
  --protocol tcp \
  --port 8080 \
  --source-group sg-alb
\`\`\`

**Root Cause**: App security group missing inbound rule for ALB traffic.

### Scenario 2: "Database Connection Timeout"

\`\`\`bash
# Check if RDS running
aws rds describe-db-instances --db-instance-identifier prod-db

# Test connection
nc -zv rds-prod.us-east-1.rds.amazonaws.com 3306

# Fix: Add inbound rule to RDS SG
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 3306 \
  --source-group sg-app
\`\`\`

**Root Cause**: RDS security group didn't allow app server source.

### Scenario 3: "High Latency / Slow Responses"

\`\`\`bash
# Check CloudFront latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name OriginLatency \
  --period 300 --statistics Average

# Check ALB response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --period 300 --statistics Average
\`\`\`

**Root Cause**: Slow database query (missing index).

### Scenario 4: "Private Instances Can't Download Updates"

\`\`\`bash
# Check NAT Gateway
aws ec2 describe-nat-gateways --filter Name=state,Values=available

# Add outbound rules
aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol udp \
  --port 53 \
  --cidr 0.0.0.0/0
\`\`\`

**Root Cause**: Security group missing outbound HTTPS/DNS rules.

### Scenario 5: "WAF Blocking Legitimate Users"

\`\`\`bash
# Check WAF logs
aws logs tail /aws/wafv2/cloudfront --follow | grep BLOCK

# Whitelist office IP
aws wafv2 create-ip-set \
  --name office-whitelist \
  --scope CLOUDFRONT \
  --ip-address-version IPV4 \
  --addresses '["203.0.113.50/32"]' \
  --region us-east-1
\`\`\`

**Root Cause**: Rate limiting rule too strict OR legitimate traffic spike.

## Troubleshooting Flowchart

\`\`\`
Issue: "Application Unreachable"
│
├─ Is DNS working? (nslookup app.example.com)
│  ├─ No → Check Route 53 hosted zone, health checks
│  └─ Yes ↓
├─ Is CloudFront reachable? (curl -I https://IP)
│  ├─ No → Check CloudFront distribution, WAF rules
│  └─ Yes ↓
├─ Is ALB responding? (curl -I https://alb-dns)
│  ├─ No → Check ALB status, listener config, security group
│  └─ Yes ↓
├─ Are targets healthy? (aws elbv2 describe-target-health)
│  ├─ No → Check app security group, health check path
│  └─ Yes ↓
└─ Issue resolved → Application working ✓
\`\`\`

## Validation Checklist

### DNS Layer (Route 53)
- [ ] Domain resolves: \`nslookup app.example.com\`
- [ ] Health checks passing: \`aws route53 get-health-check-status\`
- [ ] TTL values appropriate
- [ ] Failover routing working (if configured)

### CDN & Security Layer (CloudFront + WAF)
- [ ] CloudFront distribution deployed
- [ ] Cache behaviors configured
- [ ] WAF enabled with managed rules
- [ ] SSL certificate valid: \`curl -vI https://app.example.com\`

### Load Balancing Layer (ALB)
- [ ] ALB in multiple AZs
- [ ] Listener configured (80→443, HTTPS)
- [ ] Target groups created and targets registered
- [ ] Health check succeeds: \`curl http://target:8080/health\`

### Network Layer (VPC + Routing)
- [ ] VPC with public/private subnets across AZs
- [ ] Public route table: 0.0.0.0/0 → IGW
- [ ] Private route table: 0.0.0.0/0 → NAT

### Security Layer (Security Groups)
- [ ] ALB SG allows: TCP 80, 443 from 0.0.0.0/0
- [ ] App SG allows: TCP 8080 from ALB SG only
- [ ] App SG allows outbound: TCP 3306 (RDS), TCP 443 (APIs)
- [ ] RDS SG allows: TCP 3306 from app SG only

### Egress Control (NAT & Endpoints)
- [ ] NAT Gateway created in public subnet
- [ ] NAT has Elastic IP allocated
- [ ] Private route table: 0.0.0.0/0 → NAT Gateway
- [ ] Test: \`curl https://checkip.amazonaws.com\` from private instance

### End-to-End Testing
- [ ] Browser: \`https://app.example.com\` → 200 OK
- [ ] API: \`curl https://app.example.com/api/data\` → Expected JSON
- [ ] Database: App queries succeed in logs
- [ ] Latency: < 1 second (healthy)
- [ ] Error rate: < 0.1%

## Layer-by-Layer Debugging Commands

### DNS (Route 53)
\`\`\`bash
nslookup app.example.com
dig app.example.com +trace
aws route53 list-resource-record-sets --hosted-zone-id Z123456
\`\`\`

### CDN (CloudFront)
\`\`\`bash
curl -I https://app.example.com -v
aws cloudfront list-distributions
aws logs tail /aws/cloudfront/access-logs
\`\`\`

### WAF
\`\`\`bash
aws wafv2 get-web-acl --name production-acl --scope CLOUDFRONT
aws logs tail /aws/wafv2/cloudfront --filter-pattern "BLOCK"
\`\`\`

### ALB
\`\`\`bash
aws elbv2 describe-load-balancers
aws elbv2 describe-target-health --target-group-arn arn:aws:...
curl -I https://alb-dns.elb.amazonaws.com
\`\`\`

### Application
\`\`\`bash
ssh ec2-user@app-instance
curl http://localhost:8080/health
tail -f /var/log/app.log
\`\`\`

### Database
\`\`\`bash
mysql -h rds-endpoint -u user -p
SELECT COUNT(*) FROM information_schema.tables;
\`\`\`

## Next Steps

After understanding complete traffic flow, proceed to:

1. **Module 01**: VPC Networking Basics
2. **Module 02**: Route 53 (DNS + health checks)
3. **Module 03**: CloudFront + WAF
4. **Module 04**: Application Load Balancer
5. **Module 05**: Security Groups + NACLs
6. **Module 06**: NAT Gateway
7. **Module 07**: RDS
8. **Module 08**: EKS
9. **Module 09**: Production Troubleshooting

## Related Resources

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/)
- [AWS Networking Fundamentals](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS Reachability Analyzer](https://docs.aws.amazon.com/vpc/latest/reachability/)
- [CloudFront Troubleshooting](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/troubleshooting.html)
- [ALB Troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)

---

**Last Updated**: September 2026
**Version**: 1.0 — Complete AWS Traffic Flow Guide
"@

Set-Content -Path "$moduleDir/README.md" -Value $readmeContent
Write-Success "✓ Created: README.md"

# 4b: Architecture Diagram (SVG) - from the file we created
Write-Info "→ Creating architecture-diagram.svg..."
if (Test-Path "./architecture-diagram.svg") {
    Copy-Item "./architecture-diagram.svg" "$moduleDir/architecture-diagram.svg"
} else {
    Write-Warning "⚠ architecture-diagram.svg not found locally"
    Write-Info "  Please copy it manually from: ./architecture-diagram.svg"
}
Write-Success "✓ Created: architecture-diagram.svg"

# 4c: Quick reference guide
Write-Info "→ Creating QUICK_REFERENCE.md..."
$quickRef = @"
# Module 00 - Quick Reference

## Common Troubleshooting Scenarios

### 1. Application Unreachable
\`\`\`bash
# Quick diagnostic
nslookup app.example.com && curl -I https://app.example.com
aws elbv2 describe-target-health --target-group-arn \$TG_ARN
aws ec2 describe-security-groups --group-ids sg-app
\`\`\`

### 2. Database Connection Failed
\`\`\`bash
# Quick check
aws rds describe-db-instances --db-instance-identifier prod-db
aws ec2 describe-security-groups --group-ids sg-rds
nc -zv rds-endpoint 3306
\`\`\`

### 3. High Latency
\`\`\`bash
# Check metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name OriginLatency \
  --period 300 --statistics Average

aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --period 300 --statistics Average
\`\`\`

### 4. Private Subnet No Internet
\`\`\`bash
# Check NAT Gateway
aws ec2 describe-nat-gateways --filter Name=state,Values=available

# Test from private instance
ssh ec2-user@instance
curl https://checkip.amazonaws.com  # Should show NAT Gateway IP
\`\`\`

### 5. WAF Blocking Traffic
\`\`\`bash
# Check WAF logs
aws logs tail /aws/wafv2/cloudfront --follow | grep BLOCK

# Temporarily whitelist IP
aws wafv2 create-ip-set \
  --name test-ips \
  --scope CLOUDFRONT \
  --ip-address-version IPV4 \
  --addresses '["YOUR-IP/32"]' \
  --region us-east-1
\`\`\`

## Key Files in This Module

- **README.md** - Complete guide to 11-layer traffic flow
- **architecture-diagram.svg** - Visual representation of layers
- **QUICK_REFERENCE.md** - This file (quick troubleshooting)
- **DIAGRAMS/** - Additional reference diagrams

## Before Running Commands

1. Set AWS profile: \`export AWS_PROFILE=your-profile\`
2. Set region: \`export AWS_REGION=us-east-1\`
3. Replace placeholders: \$TG_ARN, \$ALB_ARN, sg-xxxx, etc.

## Important Notes

- **NAT Gateways cost money** - \$0.045/hour + \$0.045/GB
- **ALB costs money** - Always delete test resources
- **Security groups are stateful** - Outbound auto-allowed for inbound traffic
- **CIDR planning is hard to change** - Plan with room to grow
- **Health checks matter** - Wrong path = targets marked unhealthy

---
Learn more: Read README.md for complete details
"@

Set-Content -Path "$moduleDir/QUICK_REFERENCE.md" -Value $quickRef
Write-Success "✓ Created: QUICK_REFERENCE.md"

# 4d: Troubleshooting checklist
Write-Info "→ Creating TROUBLESHOOTING.md..."
$troubleshoot = @"
# Troubleshooting Guide - Layer by Layer

## Layer 1: DNS (Route 53)

**Symptoms**: Domain won't resolve, "name or service not known"

**Diagnostics**:
\`\`\`bash
# Check DNS resolution
nslookup app.example.com
dig app.example.com +trace

# Check Route 53
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id Z123456
aws route53 get-health-check-status --health-check-id health-123
\`\`\`

**Common Issues**:
- [ ] Domain not registered with Route 53
- [ ] Hosted zone not found
- [ ] Nameservers not updated at registrar
- [ ] Health check endpoint down (returns non-200)
- [ ] TTL too long (caching stale IP)

---

## Layer 2: CloudFront

**Symptoms**: Slow access, SSL certificate errors, WAF blocking

**Diagnostics**:
\`\`\`bash
# Check distribution
aws cloudfront get-distribution --id E123456 | jq

# Check cache
curl -I https://app.example.com -v | grep "x-cache"

# Check CloudFront logs
aws logs tail /aws/cloudfront/access-logs --follow

# Check origin
curl -I https://alb-dns.elb.amazonaws.com
\`\`\`

**Common Issues**:
- [ ] Distribution disabled
- [ ] Origin unreachable
- [ ] SSL certificate invalid/expired
- [ ] Cache policy too restrictive (not forwarding headers)
- [ ] WAF rule blocking (see Layer 3)

---

## Layer 3: WAF

**Symptoms**: 403 Forbidden, legitimate users blocked

**Diagnostics**:
\`\`\`bash
# Check WAF
aws wafv2 get-web-acl --name prod-acl --scope CLOUDFRONT

# Check logs for blocks
aws logs tail /aws/wafv2/cloudfront | grep BLOCK

# Check rate limiting
aws wafv2 get-web-acl | grep RateBasedStatement
\`\`\`

**Common Issues**:
- [ ] Rate limiting too strict
- [ ] IP blacklisted in managed rules
- [ ] Geo-blocking enabled (country blocked)
- [ ] SQL injection rule too aggressive
- [ ] Request size limit exceeded

**Fix**: Add IP to whitelist or adjust rule capacity

---

## Layer 4: ALB

**Symptoms**: 502 Bad Gateway, connection refused, timeout

**Diagnostics**:
\`\`\`bash
# Check ALB status
aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | {Name, State}'

# Check listeners
aws elbv2 describe-listeners --load-balancer-arn arn:aws:...

# Check target health
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# Check ALB security group
aws ec2 describe-security-groups --group-ids sg-alb

# Test ALB directly
curl -I https://my-alb-123456.elb.amazonaws.com
\`\`\`

**Common Issues**:
- [ ] No targets registered
- [ ] All targets unhealthy
- [ ] Health check path wrong (e.g., /healthz vs /health)
- [ ] Health check port wrong (8080 vs 3000)
- [ ] ALB security group blocks inbound 443

---

## Layer 5: VPC Routing

**Symptoms**: Traffic disappears, one-way connectivity

**Diagnostics**:
\`\`\`bash
# Check route table
aws ec2 describe-route-tables --route-table-ids rtb-123456

# Check subnet association
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-123456"

# Use Reachability Analyzer
aws ec2 describe-network-interfaces --network-interface-ids eni-123456
aws ec2 analyze-network-path \
  --source-ip 10.0.1.5 \
  --destination-ip 10.0.2.10 \
  --protocol TCP \
  --destination-port 8080
\`\`\`

**Common Issues**:
- [ ] Route table not associated with subnet
- [ ] Wrong route (points to wrong target)
- [ ] No default route (0.0.0.0/0)
- [ ] VPC CIDR too small (IP conflicts)

---

## Layer 6: Security Groups (ALB)

**Symptoms**: Connection refused, ERR_CONNECTION_REFUSED

**Diagnostics**:
\`\`\`bash
# Check ALB security group
aws ec2 describe-security-groups --group-ids sg-alb | jq '.SecurityGroups[0].IpPermissions'

# Verify port 443 is open
aws ec2 describe-security-groups --group-ids sg-alb \
  | jq '.SecurityGroups[0].IpPermissions[] | select(.FromPort==443)'

# Check outbound to app
aws ec2 describe-security-groups --group-ids sg-alb \
  | jq '.SecurityGroups[0].IpPermissionsEgress'
\`\`\`

**Common Issues**:
- [ ] Port 80 or 443 not in inbound rules
- [ ] Source CIDR too restrictive
- [ ] Rule references wrong security group
- [ ] Outbound rule blocks app traffic

**Fix**: Add/update rules in security group

---

## Layer 7: Security Groups (App)

**Symptoms**: ALB health checks fail, targets unhealthy

**Diagnostics**:
\`\`\`bash
# Check app security group
aws ec2 describe-security-groups --group-ids sg-app

# SSH to instance and test health check
ssh ec2-user@instance
curl http://localhost:8080/health

# Check if port is listening
netstat -tulpn | grep 8080
# or: ss -tulpn | grep 8080
\`\`\`

**Common Issues**:
- [ ] Port 8080 not in inbound rules
- [ ] Source SG (ALB) not referenced
- [ ] Outbound blocked (for responses)
- [ ] App not running on port 8080
- [ ] Health check path wrong

**Fix**: Add inbound rule: TCP 8080 from sg-alb

---

## Layer 8: Application

**Symptoms**: 500 errors, app crashes, slow response

**Diagnostics**:
\`\`\`bash
# SSH to instance
ssh ec2-user@instance

# Check app service
systemctl status app
journalctl -u app -f

# Check logs
tail -f /var/log/app.log

# Check resource usage
top
df -h
free -h

# Test endpoint
curl http://localhost:8080/health
curl http://localhost:8080/api/data
\`\`\`

**Common Issues**:
- [ ] App service not running
- [ ] Out of disk space
- [ ] Out of memory
- [ ] Database connection failed
- [ ] External API unreachable
- [ ] Credentials missing

---

## Layer 9: Database

**Symptoms**: Database connection timeout, slow queries, locked table

**Diagnostics**:
\`\`\`bash
# SSH to app instance and test
ssh ec2-user@instance

# Test connection
nc -zv rds-endpoint 3306

# Try connecting
mysql -h rds-endpoint -u user -p

# Check RDS status
aws rds describe-db-instances --db-instance-identifier prod-db

# Check RDS security group
aws ec2 describe-security-groups --group-ids sg-rds

# Query active connections (from RDS)
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Thread%';
\`\`\`

**Common Issues**:
- [ ] RDS not running
- [ ] RDS security group blocks app
- [ ] Credentials wrong
- [ ] Slow queries (missing indexes)
- [ ] Connection pool exhausted
- [ ] Disk space full

---

## Layer 10: NAT Gateway (Egress)

**Symptoms**: Private subnet can't reach internet, apt-get hangs

**Diagnostics**:
\`\`\`bash
# Check NAT Gateway
aws ec2 describe-nat-gateways | jq '.NatGateways[] | {NatGatewayId, State, PublicIp}'

# Check route table
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-private" \
  | jq '.RouteTables[0].Routes'

# Test from private instance
ssh ec2-user@instance
curl https://checkip.amazonaws.com  # Should show NAT IP

# Check security group
aws ec2 describe-security-groups --group-ids sg-app | grep Egress
\`\`\`

**Common Issues**:
- [ ] NAT Gateway not running
- [ ] NAT Gateway unhealthy
- [ ] Route table doesn't point to NAT
- [ ] Security group blocks outbound 443/53
- [ ] Elastic IP not allocated

---

## Quick Checklist

### Is it DNS?
- [ ] \`nslookup app.example.com\` returns IP
- [ ] Route 53 health checks passing
- [ ] Nameservers updated at registrar

### Is it CloudFront?
- [ ] \`curl -I https://app.example.com\` returns 200
- [ ] WAF not blocking (check logs)
- [ ] Origin reachable

### Is it ALB?
- [ ] \`aws elbv2 describe-target-health\` shows "healthy"
- [ ] Security group allows 80, 443 inbound
- [ ] Health check path correct

### Is it App?
- [ ] \`curl http://localhost:8080/health\` returns 200
- [ ] App service running
- [ ] Logs show no errors

### Is it Database?
- [ ] \`nc -zv rds-endpoint 3306\` succeeds
- [ ] RDS security group allows app
- [ ] Database queries fast (check slow log)

---

Last Updated: September 2026
"@

Set-Content -Path "$moduleDir/TROUBLESHOOTING.md" -Value $troubleshoot
Write-Success "✓ Created: TROUBLESHOOTING.md"

# Step 5: Git status and summary
Write-Info ""
Write-Info "STEP 5: Git preparation..."
Push-Location $RepoPath

# Check git status
$gitStatus = git status --porcelain
Write-Info ""
Write-Info "Files to be added:"
$gitStatus | Where-Object { $_ -match '^\?\?' } | ForEach-Object { Write-Info "  $($_)" }

# Step 6: Add files to git
Write-Info ""
Write-Info "STEP 6: Adding files to git..."
git add "00-aws-traffic-flow/"
Write-Success "✓ Files staged"

# Step 7: Display final summary
Write-Info ""
Write-Info "╔════════════════════════════════════════════════════════════════╗"
Write-Info "║                    DEPLOYMENT SUMMARY                         ║"
Write-Info "╚════════════════════════════════════════════════════════════════╝"
Write-Info ""
Write-Success "Module Directory: 00-aws-traffic-flow/"
Write-Success "Created Files:"
Write-Success "  ✓ README.md - Complete 11-layer traffic flow guide"
Write-Success "  ✓ architecture-diagram.svg - Visual reference"
Write-Success "  ✓ QUICK_REFERENCE.md - Quick troubleshooting commands"
Write-Success "  ✓ TROUBLESHOOTING.md - Detailed layer-by-layer guide"
Write-Info ""
Write-Info "Ready to commit!"
Write-Info ""

# Step 8: Show commit preview and push options
Write-Info "Next Steps:"
Write-Info ""
Write-Info "Option 1: Commit and Push (Automated)"
Write-Info "  .\deploy-module-00.ps1 -AutoPush"
Write-Info ""
Write-Info "Option 2: Manual Commit"
Write-Info "  git commit -m 'Add Module 00: Complete AWS Traffic Flow'"
Write-Info "  git push origin $GitBranch"
Write-Info ""
Write-Info "Option 3: Review Before Commit"
Write-Info "  git status"
Write-Info "  git diff --cached"
Write-Info "  git commit -m 'Add Module 00: Complete AWS Traffic Flow'"
Write-Info ""

# Step 9: Auto-push if requested
if ($AutoPush) {
    Write-Info ""
    Write-Info "STEP 7: Committing and pushing to GitHub..."
    
    # Commit
    git commit -m $CommitMessage
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Commit successful"
    } else {
        Write-Error "✗ Commit failed"
        Pop-Location
        exit 1
    }
    
    # Push
    git push origin $GitBranch
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Push successful"
        Write-Info ""
        Write-Info "╔════════════════════════════════════════════════════════════════╗"
        Write-Info "║            Module 00 Successfully Deployed to GitHub!         ║"
        Write-Info "╚════════════════════════════════════════════════════════════════╝"
        Write-Info ""
        Write-Success "View on GitHub:"
        Write-Info "  https://github.com/vanchinathan-Cloud/enterprise-aws-cloud-network-infrastructure/tree/$GitBranch/00-aws-traffic-flow"
    } else {
        Write-Error "✗ Push failed"
        Pop-Location
        exit 1
    }
} else {
    Write-Info "STEP 7: Ready for manual push"
    Write-Info ""
    Write-Warning "⚠ Files are staged but not committed yet"
    Write-Info "  Use 'git commit' and 'git push' manually to complete deployment"
}

Pop-Location
Write-Info ""
Write-Success "✓ Deployment script completed successfully!"
