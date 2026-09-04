# ============================================================================
# Quick Deploy - Module 00 (One Command)
# ============================================================================

# USAGE: 
#   1. Open PowerShell in your repo root
#   2. Run: pwsh -NoProfile -ExecutionPolicy Bypass -Command ". .\quick-deploy-module-00.ps1"
#   OR
#   3. Run: .\quick-deploy-module-00.ps1 -Push

param([switch]$Push)

$repo = "."
$module = "00-aws-traffic-flow"

# Create directory
if (!(Test-Path $module)) { mkdir $module | Out-Null }

# Minimal README for quick start
$readme = @"
# 0 — Complete AWS Traffic Flow

This module maps a production request through 11 networking layers.

## Quick Troubleshooting

**Application unreachable?**
\`\`\`bash
nslookup app.example.com
aws elbv2 describe-target-health --target-group-arn \$TG_ARN
aws ec2 describe-security-groups --group-ids sg-app
\`\`\`

**Database timeout?**
\`\`\`bash
nc -zv rds-endpoint 3306
aws ec2 describe-security-groups --group-ids sg-rds
\`\`\`

**High latency?**
\`\`\`bash
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime --period 300 --statistics Average
\`\`\`

## Core Layers

1. **DNS** (Route 53) - Domain resolution
2. **CDN** (CloudFront) - Global caching + WAF
3. **Load Balancer** (ALB) - TLS termination
4. **VPC** - Network routing decisions
5. **Security Groups** - Stateful firewalls
6. **Application** - Business logic
7. **Database** (RDS) - Data persistence
8. **NAT Gateway** - Egress control
9. **NACLs** - Subnet-level rules
10. **ENIs** - Network interfaces
11. **Elastic IPs** - Public addressing

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Connection Timeout | App SG missing inbound rule | Add: TCP 8080 from ALB SG |
| DB Timeout | RDS SG too restrictive | Add: TCP 3306 from app SG |
| High Latency | Slow DB query | Add index on frequently queried column |
| No Internet (Private) | Missing outbound rules | Add: TCP 443, UDP 53 egress |
| WAF Blocking | Rate limit hit | Whitelist IP or increase threshold |

## Files

- **README.md** - Full guide (see ../)
- **QUICK_REFERENCE.md** - Troubleshooting commands
- **TROUBLESHOOTING.md** - Layer-by-layer debugging
- **architecture-diagram.svg** - Visual diagram

## Next Steps

1. Read the full README.md
2. Use QUICK_REFERENCE.md for common issues
3. Proceed to Module 01 (VPC Basics)

**Last Updated**: September 2026
"@

Set-Content "$module/README.md" $readme

# Quick reference
$quick = @"
# Quick Reference - Module 00

## Test DNS
\`\`\`bash
nslookup app.example.com
dig app.example.com +trace
\`\`\`

## Test CloudFront
\`\`\`bash
curl -I https://app.example.com -v
aws logs tail /aws/wafv2/cloudfront | grep BLOCK
\`\`\`

## Test ALB
\`\`\`bash
curl -I https://alb-dns.elb.amazonaws.com
aws elbv2 describe-target-health --target-group-arn ARN
\`\`\`

## Test App
\`\`\`bash
ssh ec2-user@instance
curl http://localhost:8080/health
tail -f /var/log/app.log
\`\`\`

## Test Database
\`\`\`bash
nc -zv rds-endpoint 3306
mysql -h rds-endpoint -u user -p
\`\`\`

## Check Security Groups

### ALB SG - Should allow:
- Inbound: TCP 80, 443 from 0.0.0.0/0
- Outbound: TCP 8080 to app SG

### App SG - Should allow:
- Inbound: TCP 8080 from ALB SG
- Outbound: TCP 3306 to RDS SG
- Outbound: TCP 443 to 0.0.0.0/0

### RDS SG - Should allow:
- Inbound: TCP 3306 from app SG

## Common Fixes

### App health check fails
\`\`\`bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-app \
  --protocol tcp --port 8080 \
  --source-group sg-alb
\`\`\`

### Database connection fails
\`\`\`bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp --port 3306 \
  --source-group sg-app
\`\`\`

### Private subnet can't reach internet
\`\`\`bash
aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol tcp --port 443 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol udp --port 53 \
  --cidr 0.0.0.0/0
\`\`\`

---
For full details, read README.md in this directory.
"@

Set-Content "$module/QUICK_REFERENCE.md" $quick

# Minimal files indicator
@"
This is a minimal Module 00 setup.

For full content:
- See the refactored README at: ../README_REFACTORED.md
- Copy architecture-diagram.svg from root
- Add TROUBLESHOOTING.md from deployment scripts

To expand this module:
1. Replace README.md with content from ../README_REFACTORED.md
2. Add architecture-diagram.svg
3. Add TROUBLESHOOTING.md
4. Add diagrams/ directory with reference diagrams
"@ | Set-Content "$module/SETUP_NOTES.md"

Write-Host "✓ Module 00 created at: $module/" -ForegroundColor Green
Write-Host "  - README.md (quick start)"
Write-Host "  - QUICK_REFERENCE.md (troubleshooting)"
Write-Host "  - SETUP_NOTES.md (expansion guide)"
Write-Host ""

if ($Push) {
    Write-Host "Committing to git..." -ForegroundColor Cyan
    git add $module/
    git commit -m "Add Module 00: Complete AWS Traffic Flow - Quick Start"
    git push origin main
    Write-Host "✓ Pushed to GitHub!" -ForegroundColor Green
} else {
    Write-Host "To commit and push:" -ForegroundColor Yellow
    Write-Host "  git add $module/"
    Write-Host "  git commit -m 'Add Module 00: Complete AWS Traffic Flow'"
    Write-Host "  git push origin main"
}
