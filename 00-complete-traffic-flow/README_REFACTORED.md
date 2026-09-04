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

Follow this flow for a production request to `https://app.example.com/api/data`:

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

### Detailed Scenario: User Visits `https://app.example.com/api/data`

For specific debugging steps, root cause analysis, and bash commands for each layer, see the **Lessons Learned** section below.

## Lessons Learned

### Scenario 1: "Connection Timeout" — Users Can't Reach Application

**Error**: `Connection timeout` when visiting `https://app.example.com`

**Debugging Path**:

```bash
# Step 1: DNS works?
nslookup app.example.com
# Output: 203.0.113.1 ✓

# Step 2: Is CloudFront reachable?
curl -I https://203.0.113.1
# Output: Timeout ✗

# Step 3: Check ALB targets healthy
aws elbv2 describe-target-health --target-group-arn $TG_ARN
# Status: Unhealthy ✗ ← FOUND IT!

# Step 4: Check target security group
aws ec2 describe-security-groups --group-ids sg-app
# TCP 8080 from sg-alb: MISSING ✗

# Fix:
aws ec2 authorize-security-group-ingress \
  --group-id sg-app \
  --protocol tcp \
  --port 8080 \
  --source-group sg-alb

# Verify:
aws elbv2 describe-target-health --target-group-arn $TG_ARN
# Status: Healthy ✓
```

**Root Cause**: App security group missing inbound rule for ALB traffic.

**Key Lesson**: ALB must be able to reach app servers via security group rules; health checks fail if port/path wrong or security group blocks ALB.

---

### Scenario 2: "Database Connection Timeout" — App Can't Query Database

**Error**: Application logs show `ERROR: timeout waiting for connection to database`

**Debugging Path**:

```bash
# Step 1: Is RDS running?
aws rds describe-db-instances --db-instance-identifier prod-db
# DBInstanceStatus: available ✓

# Step 2: Can app server reach RDS port?
ssh ec2-user@app-instance
nc -zv rds-prod.us-east-1.rds.amazonaws.com 3306
# Connection refused ✗

# Step 3: Check RDS security group inbound
aws ec2 describe-security-groups --group-ids sg-rds
# TCP 3306 from sg-app: MISSING ✗

# Fix:
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 3306 \
  --source-group sg-app

# Test:
nc -zv rds-prod.us-east-1.rds.amazonaws.com 3306
# Connection successful ✓
```

**Root Cause**: RDS security group didn't allow app server source (sg-app).

**Key Lesson**: Database security groups must explicitly allow application layer; bidirectional rules aren't required (security groups are stateful), but inbound rule must reference source security group or CIDR.

---

### Scenario 3: "High Latency" — Requests Taking 5+ Seconds

**Observation**: Response time degraded from 200ms to 5000ms+

**Debugging Path**:

```bash
# Step 1: Which layer is slow? Check CloudFront metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name OriginLatency \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average

# OriginLatency: 4500ms ✗ TOO HIGH (ALB → CloudFront)

# Step 2: Check ALB target response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --period 300 \
  --statistics Average

# TargetResponseTime: 4200ms ✗ TOO HIGH (target → ALB)

# Step 3: Is database query slow?
# SSH to app and check logs
ssh ec2-user@app-instance
tail -f /var/log/app.log
# See slow database queries

# Step 4: Add database index
mysql -h rds-endpoint -u user -p
CREATE INDEX idx_user_id ON users(user_id);

# Test again:
time curl http://localhost:8080/api/data
# Real  0m0.150s ✓ Fast again
```

**Root Cause**: Slow database query (missing index on frequently queried column).

**Key Lesson**: Latency is cumulative across layers; identify slowest layer first using CloudWatch metrics, then dig deeper at that specific layer.

---

### Scenario 4: "Private Instances Can't Download Updates" — No Internet Access

**Error**: `sudo apt-get update` hangs indefinitely

**Debugging Path**:

```bash
# Step 1: Is NAT Gateway running?
aws ec2 describe-nat-gateways --filter Name=state,Values=available
# Result: Gateway found and available ✓

# Step 2: Check route table for private subnet
aws ec2 describe-route-tables \
  --filters Name=association.subnet-id,Values=subnet-private

# Routes:
# - 10.0.0.0/16 → local ✓
# - 0.0.0.0/0 → nat-xxxxx ✓ (correct)

# Step 3: Can instance reach internet?
ssh ec2-user@app-instance
curl https://checkip.amazonaws.com
# Timeout ✗

# Step 4: Check app security group outbound
aws ec2 describe-security-groups --group-ids sg-app | grep Egress
# TCP 443 to 0.0.0.0/0: MISSING ✗

# Fix:
aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Also allow DNS (port 53):
aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol udp \
  --port 53 \
  --cidr 0.0.0.0/0

# Test:
curl https://checkip.amazonaws.com
# 203.0.113.2 (NAT Gateway IP) ✓

# Now try apt-get:
sudo apt-get update
# Success! ✓
```

**Root Cause**: Security group missing outbound HTTPS (and DNS) rules.

**Key Lesson**: Private subnets need three things for internet access: (1) NAT Gateway in public subnet, (2) route table entry 0.0.0.0/0 → NAT, (3) security group allowing outbound ports (80, 443 at minimum; 53 for DNS).

---

### Scenario 5: "WAF Blocking Legitimate Users" — 403 Access Denied

**Error**: Some users see 403 Forbidden from CloudFront + WAF

**Debugging Path**:

```bash
# Step 1: Check WAF logs for blocks
aws logs tail /aws/wafv2/cloudfront --follow | grep BLOCK

# Sample blocked request:
# {
#   "action": "BLOCK",
#   "terminatingRuleId": "RateLimitRule",
#   "httpSourceIp": "203.0.113.50"
# }

# Step 2: Identify the blocking rule
# "terminatingRuleId": "RateLimitRule" = rate limiting triggered

# Step 3: Check rate limit threshold
aws wafv2 get-web-acl \
  --name production-acl \
  --scope CLOUDFRONT \
  --region us-east-1 | grep -A 10 RateBasedStatement

# Limit: 2000 requests/5 minutes

# Step 4: Solutions

# Option A: Whitelist office IP (if testing/legitimate)
aws wafv2 create-ip-set \
  --name office-whitelist \
  --scope CLOUDFRONT \
  --ip-address-version IPV4 \
  --addresses '["203.0.113.50/32"]' \
  --region us-east-1

# Option B: Increase rate limit (be careful)
# Update WAF rules with higher threshold

# Option C: Use CloudFront test mode (Count instead of Block)
aws wafv2 update-rule-group \
  --override-action Count  # Doesn't block, just counts
```

**Root Cause**: Rate limiting rule too strict OR legitimate traffic spike during testing/marketing campaign.

**Key Lesson**: WAF rules should be tight but not so restrictive they block legitimate users; always have a process to whitelist known good traffic (office IPs, CDN partners, etc.); monitor WAF logs for false positives.

---

## Complete Troubleshooting Flowchart

```
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
├─ Can app reach database? (check app logs)
│  ├─ No → Check RDS security group, credentials
│  └─ Yes ↓
└─ Issue resolved → Application working ✓

---

Issue: "Database Connection Timeout"
│
├─ Is RDS running? (aws rds describe-db-instances)
│  ├─ No → Check RDS status, restart if needed
│  └─ Yes ↓
├─ Can app reach RDS port? (nc -zv rds-endpoint 3306)
│  ├─ No → Check RDS security group inbound rule
│  └─ Yes ↓
├─ Are credentials correct? (mysql -h rds -u user -p)
│  ├─ No → Fix credentials in app config
│  └─ Yes ↓
└─ Issue resolved → Database accessible ✓

---

Issue: "High Latency / Slow Responses"
│
├─ Which layer is slow? (Check CloudWatch metrics)
│  ├─ Route 53 (DNS) → Add health checks, optimize TTL
│  ├─ CloudFront → Check cache hit ratio, origin latency
│  ├─ ALB → Check target response time, connection pooling
│  ├─ App → Check app metrics, CPU/memory, database queries
│  └─ Database → Check query performance, add indexes
└─ Optimize slowest layer → Test and revalidate ✓
```

---

## Validation Checklist

### DNS Layer (Route 53)
- [ ] Domain resolves to correct IP: `nslookup app.example.com`
- [ ] Health checks passing: `aws route53 get-health-check-status`
- [ ] TTL values appropriate for your use case
- [ ] Failover routing working (if configured)

### CDN & Security Layer (CloudFront + WAF)
- [ ] CloudFront distribution deployed and enabled
- [ ] Cache behaviors configured for each URL pattern (APIs, static assets)
- [ ] WAF enabled with managed rules (AWS Managed Rules for Core Rule Set)
- [ ] SSL certificate valid: `curl -vI https://app.example.com`
- [ ] WAF logs readable: `aws logs tail /aws/wafv2/cloudfront`

### Load Balancing Layer (ALB)
- [ ] ALB exists in multiple AZs (high availability)
- [ ] Listener configured on 443 with HTTPS
- [ ] Listener rule (host-based or path-based) routes to correct target group
- [ ] Target group registered with at least 2 targets
- [ ] Health check path correct (usually /health, /status, or /ping)
- [ ] Health check succeeds: `curl http://target:8080/health`

### Network Layer (VPC + Routing)
- [ ] VPC created with appropriate CIDR (e.g., 10.0.0.0/16)
- [ ] Public subnets in multiple AZs
- [ ] Private subnets in multiple AZs
- [ ] Route tables: public subnets route 0.0.0.0/0 → IGW
- [ ] Route tables: private subnets route 0.0.0.0/0 → NAT
- [ ] Subnets correctly associated with route tables

### Security Layer (Security Groups)
- [ ] ALB SG allows inbound: TCP 80 (redirect), TCP 443 from 0.0.0.0/0
- [ ] ALB SG allows outbound: TCP 8080 to app SG
- [ ] App SG allows inbound: TCP 8080 from ALB SG only
- [ ] App SG allows outbound: TCP 3306 to RDS SG (database)
- [ ] App SG allows outbound: TCP 443 to 0.0.0.0/0 (external APIs)
- [ ] RDS SG allows inbound: TCP 3306 from app SG only

### Egress Control (NAT & Endpoints)
- [ ] NAT Gateway created in public subnet
- [ ] NAT Gateway has Elastic IP allocated
- [ ] Private route table points 0.0.0.0/0 → NAT Gateway
- [ ] (Optional) S3 Gateway Endpoint created for private S3 access
- [ ] Test: `curl https://checkip.amazonaws.com` from private instance returns NAT Gateway IP

### Application Layer
- [ ] App servers running (EC2, ECS, EKS)
- [ ] App health check endpoint responds 200: `curl http://localhost:8080/health`
- [ ] App logs indicate successful startup: `tail -f /var/log/app.log`
- [ ] App can connect to database (test with `SELECT 1;`)
- [ ] App can reach external services if needed

### Database Layer (RDS)
- [ ] RDS instance running and available: `aws rds describe-db-instances`
- [ ] Database accessible from app: `mysql -h rds-endpoint -u user -p`
- [ ] Backups enabled and recent: `aws rds describe-db-instances | grep BackupRetention`
- [ ] Read replicas available if multi-AZ: `aws rds describe-db-instances | grep MultiAZ`

### End-to-End Testing
- [ ] **Browser test**: User visits `https://app.example.com` → Responds with 200 ✓
- [ ] **API test**: `curl https://app.example.com/api/data` → Returns expected JSON ✓
- [ ] **Database test**: App queries execute successfully in logs ✓
- [ ] **Latency test**: End-to-end latency < 1 second (healthy)
  - CloudFront cache hit: < 50ms
  - ALB processing: < 100ms
  - App processing: < 200ms
  - Database query: < 100ms
- [ ] **Error rate**: < 0.1% (monitor in CloudWatch)
- [ ] **Cache hit ratio**: > 80% for static assets
- [ ] **SSL Labs score**: A or higher (SSL configuration optimal)

---

## Layer-by-Layer Debugging Commands

### Layer 1: DNS (Route 53)
```bash
nslookup app.example.com
dig app.example.com +trace
aws route53 list-resource-record-sets --hosted-zone-id Z123456
aws route53 get-health-check-status --health-check-id health-check-id
```

### Layer 2: CDN (CloudFront)
```bash
curl -I https://app.example.com -v  # Check cache headers
aws cloudfront list-distributions
aws cloudfront get-distribution --id E123456
aws logs tail /aws/cloudfront/access-logs
```

### Layer 3: WAF
```bash
aws wafv2 get-web-acl --name production-acl --scope CLOUDFRONT
aws logs tail /aws/wafv2/cloudfront --filter-pattern "BLOCK"
```

### Layer 4: ALB
```bash
aws elbv2 describe-load-balancers
aws elbv2 describe-target-health --target-group-arn arn:aws:...
curl -I https://alb-dns.elb.amazonaws.com
aws elbv2 describe-listeners --load-balancer-arn arn:aws:...
```

### Layer 5: VPC Routing
```bash
aws ec2 describe-route-tables --route-table-ids rtb-123456
aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=subnet-123456
```

### Layer 6: Security Groups
```bash
aws ec2 describe-security-groups --group-ids sg-12345678
aws ec2 describe-security-group-rules --filters Name=group-id,Values=sg-12345678
```

### Layer 7: Application
```bash
ssh ec2-user@app-instance
curl http://localhost:8080/health
tail -f /var/log/app.log
ps aux | grep java  # or python, node, etc.
```

### Layer 8: Database
```bash
mysql -h rds-endpoint -u user -p
SELECT COUNT(*) FROM information_schema.tables;
SHOW PROCESSLIST;  # Check active connections
```

---

## Request Flow Timing Reference

### Healthy Request (CloudFront cache hit) — ~250ms total

```
1. DNS Resolution: 10ms → Route 53 lookup
2. CloudFront Edge: 20ms → TCP handshake + TLS
3. CloudFront Processing: 5ms → Cache check + WAF
4. Forward to ALB: 50ms → Transfer request to origin
5. ALB Processing: 10ms → TLS termination + routing
6. App Processing: 100ms → Business logic + database
7. Return Path: 55ms → Response through layers
───────────────
TOTAL: ~250ms ✓ (healthy)
```

### Cache Miss (all layers) — ~290ms total

```
1. DNS: 10ms
2. CloudFront (no cache): 60ms
3. ALB → App: 60ms
4. App → Database: 100ms
5. Response path: 60ms
───────────────
TOTAL: ~290ms (acceptable)
```

### With Database Timeout — ~5250ms total ✗

```
1-6. Normal path: ~250ms
7. Database timeout: +5000ms
───────────────
TOTAL: ~5250ms ✗ (bad)
```

---

## Next Steps & Integration

This module should be read **first** in the portfolio. After understanding the complete traffic flow:

1. **Module 01**: VPC Networking Basics (foundational)
2. **Module 02**: Route 53 (DNS + health checks)
3. **Module 03**: CloudFront + WAF (CDN + security)
4. **Module 04**: Application Load Balancer (load balancing)
5. **Module 05**: Security Groups + NACLs (access control)
6. **Module 06**: NAT Gateway (egress control)
7. **Module 07**: RDS (database layer)
8. **Module 08**: EKS (compute layer)
9. **Module 09**: Production Troubleshooting (advanced)

**Use This Module When**:
- Onboarding new team members to AWS
- Debugging multi-layer issues (not sure where problem is)
- Planning architecture changes
- Conducting incident post-mortems
- Training for AWS Solutions Architect certification

---

## Related Resources

- [AWS Well-Architected Framework — Networking](https://docs.aws.amazon.com/wellarchitected/latest/userguide/workload-review-rel-networking.html)
- [AWS Networking Fundamentals](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Introduction.html)
- [AWS Reachability Analyzer](https://docs.aws.amazon.com/vpc/latest/reachability/) — Visualize traffic paths
- [AWS Troubleshooting Guide](https://docs.aws.amazon.com/general/latest/gr/troubleshooting.html)
- [CloudFront Troubleshooting](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/troubleshooting.html)
- [ALB Troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)

---

## Lessons Learned

- **A request's path is never direct** — every layer adds latency and failure points; understand the entire path before blaming any single component.
- **Stateful security groups are powerful** — inbound rules are what matter; responses auto-return; don't overthink outbound unless blocking access.
- **DNS is the first layer** — if DNS fails, nothing else matters; make health checks meaningful (don't just check port availability).
- **Caching is a double-edged sword** — CloudFront speeds up reads but requires Cache-Control headers to be correct; APIs should never be cached unless explicitly intended.
- **NAT Gateways cost money** — every byte egressing from private subnets through NAT is billable; consider VPC endpoints for AWS services (S3, DynamoDB).
- **Security groups compound** — traffic must pass through ALB SG AND app SG AND NACL (rarely); debug layer by layer, not all at once.
- **Latency is cumulative** — a 100ms delay at each of 5 layers = 500ms total; identify the slowest layer first.
- **WAF rules need tuning** — managed rules are safe defaults but may be too strict; whitelist known good traffic, review false positives regularly.
- **Database is usually the bottleneck** — query performance, indexing, and connection pooling matter more than network latency for most applications.
- **Once you've completed this lab, delete test resources** — NAT Gateways and running EC2 instances bill hourly; leftover resources cost money every month.

---

**Last Updated**: September 2026  
**Version**: 1.0 — Complete AWS Traffic Flow Guide
