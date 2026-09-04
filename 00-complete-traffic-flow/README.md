# Module 0: Complete AWS Traffic Flow — Request Journey Through All Layers

## 🎯 Overview

A production request traveling to your application doesn't take a direct path. It passes through **7+ networking layers**, each performing critical functions: DNS resolution, global caching, security filtering, load balancing, routing, access control, and private service connectivity.

**Why This Matters**: When something breaks (application unreachable, database timeout, slow response), you won't know which layer to investigate without understanding the complete flow. A methodical troubleshooting approach—tracing the request path step by step—reveals the issue 90% of the time.

**This Module**: Maps the complete journey of a production request, showing what happens at each layer, common failure points, and how to debug the entire chain.

---

## 🔄 The Complete Traffic Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET (User)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    1. DNS Resolution
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │      Route 53 (DNS Query)              │
        │  - Resolves example.com to IP          │
        │  - Health checks active endpoints      │
        │  - Returns endpoint IP (203.0.113.1)   │
        └────────────────────┬───────────────────┘
                             │
                    2. Global Distribution
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  CloudFront (CDN) + WAF                │
        │  - Checks cache hit (images, static)   │
        │  - WAF inspects request                │
        │  - Blocks malicious traffic            │
        │  - Routes to origin (ALB)              │
        └────────────────────┬───────────────────┘
                             │
                    3. TLS Termination
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  Application Load Balancer (ALB)       │
        │  - Accepts HTTPS connection            │
        │  - Terminates TLS/SSL                  │
        │  - Checks target health                │
        │  - Routes to healthy targets           │
        └────────────────────┬───────────────────┘
                             │
              4. VPC Boundary & Routing
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  Virtual Private Cloud (VPC)           │
        │  - Public Subnet (ALB lives here)      │
        │  - Route Table: 0.0.0.0/0 → IGW       │
        │  - Determines if traffic is local      │
        └────────────────────┬───────────────────┘
                             │
          5. First Security Layer
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  ALB Security Group                    │
        │  - Stateful firewall                   │
        │  - Allows: TCP 80, 443 from 0.0.0.0/0 │
        │  - Response auto-allowed               │
        │  - Blocks other protocols              │
        └────────────────────┬───────────────────┘
                             │
            6. Forward to App Servers
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  Target Group (Private Subnet)         │
        │  - EC2/ECS/EKS instances (port 8080)   │
        │  - ALB performs health checks (30s)    │
        │  - Load balances across targets        │
        │  - Round-robin or least outstanding    │
        └────────────────────┬───────────────────┘
                             │
          7. Second Security Layer
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  App Server Security Group             │
        │  - Stateful firewall (per instance)    │
        │  - Allows: TCP 8080 from ALB SG only   │
        │  - Blocks SSH from internet            │
        │  - Responds to incoming traffic        │
        └────────────────────┬───────────────────┘
                             │
        8. Application Processing
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  Application Server (EKS Pod/ECS)      │
        │  - Receives HTTP request on :8080      │
        │  - Processes business logic            │
        │  - Generates response                  │
        │  - May call external services          │
        └────────────────────┬───────────────────┘
                             │
        9. Database Layer Access
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  RDS Database (Private Subnet)         │
        │  - App initiates connection :3306      │
        │  - Encrypted tunnel (mutual TLS)       │
        │  - Returns query results               │
        │  - Auto-scales read replicas           │
        └────────────────────┬───────────────────┘
                             │
       10. Egress Control
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  NAT Gateway / VPC Endpoints           │
        │  - App calls external API              │
        │  - NAT translates private IP           │
        │  - Appears as public IP (203.0.113.2)  │
        │  - Response returns through NAT        │
        └────────────────────┬───────────────────┘
                             │
        11. Response Path (Reverse)
                             │
        Response travels back through:
        - App → ALB → CloudFront → User
        - Data cached in CloudFront for next request
        - Response logged in ALB access logs
        - Metrics sent to CloudWatch
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │  User Receives Response                │
        │  - 200 OK, content delivered           │
        │  - Cache headers determine reuse       │
        │  - Browser caches as configured        │
        └────────────────────────────────────────┘
```

---

## 🔧 Core Components (Quick Reference)

| Layer | Component | Purpose | Failure Impact |
|-------|-----------|---------|-----------------|
| **1** | Route 53 | DNS resolution | Domain unreachable |
| **2** | CloudFront + WAF | CDN + security | Slow/blocked access |
| **3** | ALB | Load balancing | Requests fail |
| **4** | VPC + Route Tables | Network routing | Traffic lost |
| **5** | Security Groups | Access control | Connections refused |
| **6** | NAT Gateway | Egress control | Private outbound blocked |
| **7** | EKS/RDS | Workloads | Application error |

---

## 🛠️ Build Steps — Tracing a Real Request

### Scenario: User visits `https://app.example.com/api/data`

#### Step 1: DNS Lookup (Route 53)

```bash
# User's browser resolves domain
nslookup app.example.com

# Route 53 returns:
# Name:    app.example.com
# Address: 203.0.113.1  (CloudFront edge location)

# Behind the scenes:
# 1. Route 53 receives query
# 2. Checks health of registered endpoints
# 3. If primary unhealthy → routes to secondary
# 4. Returns endpoint IP
```

**What can break**:
- ❌ Domain name not registered
- ❌ Route 53 hosted zone not found
- ❌ Health check failing (primary down)
- ❌ Nameservers not updated at registrar

---

#### Step 2: Connect to CloudFront Edge (CloudFront + WAF)

```bash
# Browser connects to CloudFront edge (nearest location)
# Example: User in London → CloudFront London edge

curl -I https://app.example.com/api/data

# CloudFront checks:
# 1. Is /api/data cached? 
#    - Cache key: /api/data (query strings, cookies)
#    - TTL: 0 (APIs not cached, forward to origin)
# 2. Run WAF rules:
#    - Rate limiting: < 2000 requests/5 min? ✓
#    - SQL injection patterns? ✓ Clean
#    - Geo-blocking: Allowed country? ✓
# 3. Origin unreachable? Use stale cache if available
```

**What can break**:
- ❌ WAF rule too strict (blocks legitimate traffic)
- ❌ CloudFront origin not responding
- ❌ SSL certificate expired
- ❌ Cache policy prevents forwarding required headers

---

#### Step 3: Forward to ALB (Application Load Balancer)

```bash
# CloudFront forwards request to origin (ALB)
# Request includes X-Forwarded-For header (real client IP)

GET /api/data HTTP/1.1
Host: my-alb-123456789.us-east-1.elb.amazonaws.com
X-Forwarded-For: 203.0.113.50  (real user IP from London)
X-Forwarded-Proto: https
CloudFront-Is-Desktop-Viewer: true

# ALB receives request:
# 1. Check HTTPS listener (port 443) → HTTPS listener configured ✓
# 2. Run listener rules:
#    - If Host: api.example.com → API target group ✓
#    - If Path: /api/* → API target group ✓
# 3. Select target group → forward to healthy targets
```

**What can break**:
- ❌ ALB security group blocks port 443
- ❌ Listener rules don't match (wrong target group)
- ❌ No targets registered or all unhealthy
- ❌ SSL certificate missing/invalid
- ❌ Target group health check path wrong

---

#### Step 4: Route Within VPC

```bash
# Request enters VPC (public subnet)
# Route table: Which direction?

Route Table (Public Subnets):
├── 10.0.0.0/16 (local) → Local (stay in VPC)
├── 0.0.0.0/0 → igw-12345 (to internet)
└── No other routes

# Decision: Destination = 10.0.2.1 (app server in private subnet)
# → 10.0.0.0/16 matches → LOCAL route
# → Stay in VPC, don't leave through IGW
```

**What can break**:
- ❌ Route table not associated with subnet
- ❌ Wrong route (points to wrong target)
- ❌ No route to destination (packet dropped)
- ❌ Route via wrong NAT Gateway

---

#### Step 5: Check ALB Security Group

```bash
# Packet tries to reach ALB

ALB Security Group (sg-alb):
├── Inbound Rules:
│   ├── TCP 80 from 0.0.0.0/0 ✓ Allowed
│   ├── TCP 443 from 0.0.0.0/0 ✓ Allowed
│   └── Other protocols → Blocked
├── Outbound Rules:
│   ├── All traffic to app servers → Allowed
│   └── (Stateful: response auto-allowed)
└── Result: ✓ ALLOW

# Security group is STATEFUL:
# Inbound traffic allowed → Outbound response auto-allowed
```

**What can break**:
- ❌ Port 80/443 not in inbound rules
- ❌ Source CIDR too restrictive (e.g., 10.0.0.0/24, user from 10.0.1.0/24)
- ❌ Outbound rule blocks response
- ❌ Wrong security group attached

---

#### Step 6: ALB Forwards to App Target

```bash
# ALB has target group: web-targets
# Registered targets:
# ├── i-app-1 (10.0.2.10:8080) Status: Healthy ✓
# ├── i-app-2 (10.0.2.20:8080) Status: Healthy ✓
# └── i-app-3 (10.0.2.30:8080) Status: Healthy ✓

# ALB health check (every 30 seconds):
curl -i http://10.0.2.10:8080/health
# HTTP 200 OK ✓ Healthy

# ALB forwards to target (round-robin):
# Request #1 → i-app-1
# Request #2 → i-app-2
# Request #3 → i-app-3
# Request #4 → i-app-1 (repeat)
```

**What can break**:
- ❌ Health check path wrong (e.g., /healthz instead of /health)
- ❌ Health check port wrong (8080 vs 3000)
- ❌ All targets unhealthy (no targets available)
- ❌ Target security group blocks ALB
- ❌ Network ACL blocks traffic

---

#### Step 7: App Server Security Group

```bash
# Request tries to reach app server (10.0.2.10:8080)

App Server Security Group (sg-app):
├── Inbound Rules:
│   ├── TCP 8080 from sg-alb ✓ Allowed
│   ├── TCP 22 from sg-bastion → SSH only
│   └── Other → Blocked
├── Outbound Rules:
│   ├── TCP 3306 to sg-rds (MySQL)
│   ├── TCP 443 to 0.0.0.0/0 (external APIs)
│   └── Other → Blocked (restrictive)
└── Result: ✓ ALLOW

# Stateful: App can respond to ALB
```

**What can break**:
- ❌ Port 8080 rule missing or wrong source SG
- ❌ Outbound rule blocks database access
- ❌ Outbound rule blocks external API calls
- ❌ NACL blocks traffic (rare, but possible)

---

#### Step 8: Application Processing

```bash
# App server receives HTTP request on :8080
# Processes request:

Application Logic:
1. Receive GET /api/data
2. Check authentication/authorization
3. Query database for data
4. Call external API (if needed)
5. Format response
6. Send 200 OK + JSON

# Example Python Flask:
@app.route('/api/data')
def get_data():
    # Query database
    data = db.query("SELECT * FROM users")
    
    # Call external API
    response = requests.get('https://external-api.com/data')
    
    # Return response
    return jsonify(data)
```

**What can break**:
- ❌ Application error (500)
- ❌ Database unreachable (timeout)
- ❌ External API unreachable
- ❌ Authentication failing
- ❌ Permissions issue (403)

---

#### Step 9: Database Access

```bash
# App server (10.0.2.10) connects to RDS

Connection Attempt:
1. Destination: rds-instance.us-east-1.rds.amazonaws.com:3306
2. Resolve DNS to private IP (10.0.3.10)
3. Check security groups:

   RDS Security Group (sg-rds):
   ├── Inbound Rules:
   │   ├── TCP 3306 from sg-app ✓ Allowed
   │   └── Other → Blocked
   ├── Outbound Rules: None (databases don't need outbound)
   └── Result: ✓ ALLOW

4. Establish encrypted connection (mutual TLS)
5. Authenticate with username/password
6. Execute SQL query
7. Return results to application
```

**What can break**:
- ❌ RDS security group doesn't allow app source
- ❌ RDS not in right subnet group
- ❌ Database credentials wrong
- ❌ Database not running/available
- ❌ Network ACL blocks 3306

---

#### Step 10: Egress (Private → Internet)

```bash
# App calls external API
curl https://external-api.com/data

# App server (10.0.2.10, private subnet)
# → NAT Gateway (public subnet, 203.0.113.2)
# → Internet
# → external-api.com

# NAT Translation:
Source IP: 10.0.2.10 → 203.0.113.2
Destination: external-api.com

# Response:
Source IP: external-api.com
Destination: 203.0.113.2 → NAT translates back to 10.0.2.10
```

**What can break**:
- ❌ No NAT Gateway (private subnet can't reach internet)
- ❌ NAT Gateway not in route table
- ❌ NAT Gateway unhealthy/down
- ❌ Security group blocks outbound
- ❌ VPC endpoint needed instead (for AWS services)

---

#### Step 11: Response Path (Reverse Flow)

```
App Server → ALB → CloudFront → User

1. App sends 200 OK + JSON response
2. ALB receives response
3. ALB adds headers (X-Amzn-Trace-Id, etc.)
4. CloudFront receives response
5. Check cache headers (Cache-Control, Expires)
6. Cache response (if appropriate)
7. Return to user
8. Browser renders response
```

---

## ⚠️ Lessons Learned — Real Troubleshooting Scenarios

### 🔴 **Scenario 1: "Connection Timeout" — Users Can't Reach Application**

**Error**: `Connection timeout` when visiting `https://app.example.com`

**Debugging Path**:

```bash
# Step 1: DNS works?
nslookup app.example.com
# Output: 203.0.113.1 ✓

# Step 2: CloudFront reachable?
curl -I https://203.0.113.1
# Output: Timeout ✗

# Step 3: Is CloudFront origin (ALB) alive?
aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN
# Status: active, State: active ✓

# Step 4: ALB targets healthy?
aws elbv2 describe-target-health --target-group-arn $TG_ARN
# Status: Unhealthy ✗ ← FOUND IT!

# Step 5: Why unhealthy?
# Check target security group:
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

# Test:
curl https://app.example.com
# Success!
```

**Root Cause**: App security group missing inbound rule for ALB.

---

### 🔴 **Scenario 2: "Database Connection Timeout" — App Can't Query Database**

**Error**: Application logs show `ERROR: timeout waiting for connection to database`

**Debugging Path**:

```bash
# Step 1: Is RDS running?
aws rds describe-db-instances --db-instance-identifier prod-db
# DBInstanceStatus: available ✓

# Step 2: Can app server reach RDS port?
# SSH to app server and test:
nc -zv rds-prod.us-east-1.rds.amazonaws.com 3306
# Connection refused ✗

# Step 3: Check RDS security group:
aws ec2 describe-security-groups --group-ids sg-rds
# TCP 3306 from sg-app: MISSING ✗

# Fix:
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 3306 \
  --source-group sg-app

# Test again:
nc -zv rds-prod.us-east-1.rds.amazonaws.com 3306
# Connection successful ✓

# Check app logs:
# Database queries now succeeding ✓
```

**Root Cause**: RDS security group didn't allow app server source.

---

### 🔴 **Scenario 3: "High Latency" — Requests Taking 5+ Seconds**

**Observation**: Response time degraded from 200ms to 5000ms+

**Debugging Path**:

```bash
# Step 1: Which layer is slow?
# Check CloudFront metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name OriginLatency \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average

# OriginLatency: 4500ms (ALB → CloudFront) ✗ TOO HIGH

# Step 2: Check ALB response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average

# TargetResponseTime: 4200ms (Target → ALB) ✗ TOO HIGH

# Step 3: Which target is slow?
# Check individual target metrics or SSH to target:
time curl http://localhost:8080/health
# Real  0m4.215s ✗ App is slow

# Step 4: Is app hitting database?
# Check database query performance:
SELECT DISTINCT query, time
FROM slow_log
ORDER BY time DESC
LIMIT 10;

# Found: Query taking 4 seconds ✗

# Step 5: Add database index:
CREATE INDEX idx_user_id ON users(user_id);

# Test again:
time curl http://localhost:8080/api/data
# Real  0m0.150s ✓ Fast again

# Verify metrics:
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2024-01-02T00:00:00Z \
  --end-time 2024-01-03T00:00:00Z \
  --period 300 \
  --statistics Average

# TargetResponseTime: 150ms ✓ Restored to normal
```

**Root Cause**: Slow database query (missing index).

---

### 🔴 **Scenario 4: "Private Instances Can't Download Updates" — No Internet Access**

**Error**: `sudo apt-get update` hangs indefinitely

**Debugging Path**:

```bash
# Step 1: Is NAT Gateway running?
aws ec2 describe-nat-gateways --filter Name=state,Values=available

# If empty: No NAT Gateway ✗

# Step 2: Check route table:
aws ec2 describe-route-tables \
  --filters Name=association.subnet-id,Values=subnet-private
  
# Routes:
# - 10.0.0.0/16 → local ✓
# - 0.0.0.0/0 → nat-xxxxx ✓

# NAT Gateway route exists, but status?
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxxxx
# State: available ✓
# Status: available ✓

# Step 3: Can app reach internet?
# SSH to instance:
curl https://checkip.amazonaws.com
# Timeout ✗

# Step 4: Security group allows outbound?
aws ec2 describe-security-groups --group-ids sg-app | grep Egress
# TCP 443 to 0.0.0.0/0: MISSING ✗

# Fix:
aws ec2 authorize-security-group-egress \
  --group-id sg-app \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Test:
curl https://checkip.amazonaws.com
# 203.0.113.2 (NAT Gateway IP) ✓

# Try apt-get:
sudo apt-get update
# Success! ✓
```

**Root Cause**: Security group missing outbound HTTPS rule.

---

### 🔴 **Scenario 5: "WAF Blocking Legitimate Users" — 403 Access Denied**

**Error**: Some users see 403 Forbidden from CloudFront

**Debugging Path**:

```bash
# Step 1: Check WAF logs
aws logs tail /aws/wafv2/cloudfront --follow | grep BLOCK

# Sample blocked request:
# {
#   "action": "BLOCK",
#   "terminatingRuleId": "RateLimitRule",
#   "httpSourceIp": "203.0.113.50",
#   "httpRequest": {
#     "clientIp": "203.0.113.50",
#     "country": "US",
#     "method": "GET"
#   }
# }

# Step 2: Identify the rule blocking:
# "terminatingRuleId": "RateLimitRule"
# This means rate limiting rule triggered

# Step 3: Check rate limit threshold
aws wafv2 get-web-acl --name production-acl --scope CLOUDFRONT --region us-east-1 \
  | grep -A 10 RateBasedStatement

# Limit: 2000 requests/5 minutes
# This is the standard threshold, but office IP may be exceeding it during testing

# Step 4: Solutions:
# Option A: Whitelist office IP (if legitimate)
aws wafv2 create-ip-set \
  --name office-whitelist \
  --scope CLOUDFRONT \
  --ip-address-version IPV4 \
  --addresses '["203.0.113.50/32"]' \
  --region us-east-1

# Option B: Increase rate limit threshold (be careful)
aws wafv2 update-web-acl \
  --name production-acl \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --rules file://updated-rules.json  # Increase limit to 5000

# Option C: Use CloudFront test mode (Count instead of Block)
aws wafv2 update-rule-group \
  --override-action Count  # Doesn't block, just counts
```

**Root Cause**: Rate limiting rule too strict OR legitimate traffic spike.

---

## ✅ Validation Checklist — Complete Traffic Flow

### DNS Layer (Route 53)
- [ ] Domain resolves to correct IP
- [ ] Health checks passing
- [ ] TTL values appropriate
- [ ] Failover routing working (if configured)
- [ ] **Test**: `nslookup app.example.com` returns correct IP

### CDN & Security Layer (CloudFront + WAF)
- [ ] CloudFront distribution deployed
- [ ] Cache behaviors configured for each URL pattern
- [ ] WAF enabled with managed rules
- [ ] SSL certificate valid
- [ ] **Test**: `curl -I https://app.example.com` returns 200, includes cache headers

### Load Balancing Layer (ALB)
- [ ] ALB in multiple AZs
- [ ] Listeners configured (80→443 redirect, HTTPS)
- [ ] Target groups created and targets registered
- [ ] **Test**: `curl https://alb-dns.elb.amazonaws.com` succeeds

### Network Layer (VPC + Routing)
- [ ] VPC with public/private subnets across AZs
- [ ] Route tables correctly associated
- [ ] Public subnets have route: 0.0.0.0/0 → IGW
- [ ] Private subnets have route: 0.0.0.0/0 → NAT
- [ ] **Test**: Route table shows all expected routes

### Security Layer (Security Groups + NACLs)
- [ ] ALB SG allows inbound 80, 443 from 0.0.0.0/0
- [ ] App SG allows inbound 8080 from ALB only
- [ ] App SG allows outbound to database
- [ ] RDS SG allows inbound 3306 from app only
- [ ] **Test**: `nc -zv target-ip port` succeeds/fails as expected

### Egress Control (NAT + Endpoints)
- [ ] NAT Gateway created in public subnet
- [ ] Private route table points to NAT for 0.0.0.0/0
- [ ] S3 Gateway Endpoint created (if using S3)
- [ ] **Test**: Private instance can `curl https://checkip.amazonaws.com`

### Application Layer (EKS/Compute)
- [ ] App servers running and healthy
- [ ] Health check endpoint responds 200
- [ ] Application can connect to database
- [ ] **Test**: App logs show successful database queries

### Database Layer (RDS)
- [ ] RDS instance running and available
- [ ] Security group allows app traffic
- [ ] Database credentials correct
- [ ] **Test**: `mysql -h rds-endpoint -u user -p` succeeds

### End-to-End Validation
- [ ] **User's browser** → CloudFront → ALB → App → Database → Response
- [ ] **Latency** < 1 second (CloudFront cache hit < 50ms)
- [ ] **Error rate** < 0.1% (monitor in CloudWatch)
- [ ] **Cache hit ratio** > 80% (for static content)
- [ ] **SSL Labs** score A+ (SSL config optimal)

---

## 🔍 Complete Troubleshooting Flowchart

```
Issue: "Application Unreachable"
│
├─ Is DNS working? (nslookup app.example.com)
│  ├─ No → Check Route 53 hosted zone, health checks
│  └─ Yes ↓
├─ Is CloudFront reachable? (curl -I https://IP)
│  ├─ No → Check CloudFront distribution status
│  └─ Yes ↓
├─ Is ALB reachable? (curl -I https://alb-dns)
│  ├─ No → Check ALB status, security group
│  └─ Yes ↓
├─ Are targets healthy? (aws elbv2 describe-target-health)
│  ├─ No → Check app security group, health check path
│  └─ Yes ↓
├─ Is app responding? (curl http://target:8080)
│  ├─ No → SSH to instance, check logs, app service status
│  └─ Yes ↓
├─ Can app reach database? (check app logs)
│  ├─ No → Check RDS security group, database connectivity
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
│  ├─ Route 53 (DNS) slow → Add health checks
│  ├─ CloudFront slow → Check cache hit ratio, origin latency
│  ├─ ALB slow → Check target response time
│  ├─ App slow → Check app metrics, database queries
│  └─ Database slow → Check database query performance
└─ Optimize slowest layer → Test again ✓
```

---

## 📊 Request Flow with Timings

```
Total Request Latency: ~250ms (CloudFront cache hit)

1. DNS Resolution: 10ms
   └─ Route 53 lookup

2. Connect to CloudFront: 20ms
   └─ TCP handshake + TLS

3. CloudFront Processing: 5ms
   ├─ Check cache
   ├─ Run WAF rules
   └─ Check origin health

4. Forward to ALB: 50ms
   ├─ Transfer request
   └─ Wait for origin response

5. ALB Processing: 10ms
   ├─ TLS termination
   ├─ Run listener rules
   └─ Route to target group

6. App Processing: 100ms
   ├─ Receive request
   ├─ Process business logic
   ├─ Query database
   └─ Generate response

7. Return Path: 55ms
   ├─ Response → ALB
   ├─ Response → CloudFront
   ├─ CloudFront cache response
   └─ Response → User

TOTAL: ~250ms (healthy cache hit)

vs.

Cache miss (all layers involved):
1. DNS: 10ms
2. CloudFront → Origin: 60ms (no cache)
3. ALB → App: 60ms (no cache)
4. App → Database: 100ms
5. Response path: 60ms
TOTAL: ~290ms

vs.

Database timeout (bad):
1-5. Same: ~250ms
6. Database query timeout: +5000ms
TOTAL: ~5250ms ✗
```

---

## 🎯 Layer-by-Layer Debugging Checklist

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
```

### Layer 5: Routing
```bash
aws ec2 describe-route-tables --route-table-ids rtb-123456
aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=subnet-123456
```

### Layer 6: Security Groups
```bash
aws ec2 describe-security-groups --group-ids sg-12345678
# Check: inbound rules, outbound rules, referenced SGs
```

### Layer 7: App
```bash
ssh ec2-user@app-instance
curl http://localhost:8080/health
tail -f /var/log/app.log
```

### Layer 8: Database
```bash
mysql -h rds-endpoint -u user -p
SELECT COUNT(*) FROM information_schema.tables;
```

---

## 📚 Next Steps & Integration

This module should be the **0th module** — read first, refer back often.

After understanding complete traffic flow:

1. **Module 01**: Route 53 (DNS layer)
2. **Module 02**: CloudFront + WAF (CDN + security)
3. **Module 03**: ALB (load balancing)
4. **Module 04**: VPC (routing layer)
5. **Module 05**: Security Groups/NACLs (access control)
6. **Module 06**: NAT/Endpoints (egress control)
7. **Module 07**: EKS (compute layer)
8. **Module 08**: RDS (data layer)
9. **Module 09**: Troubleshooting (reference guide)

**Use This Module When**:
- Debugging multi-layer issues
- Onboarding new team members
- Planning architecture changes
- Investigating production incidents
- Conducting post-mortems

---

## 🔗 Related Resources

- [AWS Well-Architected Framework — Networking](https://docs.aws.amazon.com/wellarchitected/latest/userguide/workload-review-rel-networking.html)
- [AWS Networking Fundamentals](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Introduction.html)
- [AWS Troubleshooting Guide](https://docs.aws.amazon.com/general/latest/gr/troubleshooting.html)
- [Reachability Analyzer](https://docs.aws.amazon.com/vpc/latest/reachability/) — Visualize traffic paths

---

**Last Updated**: September 2026  
**Version**: 1.0 - Complete Traffic Flow Guide
