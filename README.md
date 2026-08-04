# Enterprise AWS Cloud Network Infrastructure

Hands-on labs and reference builds for designing, deploying, securing, and validating
production-grade AWS network infrastructure — VPC architecture, hybrid connectivity,
segmentation, monitoring, and security controls.

This isn't a collection of diagrams. Every module here was actually built and torn
down in an AWS account, with the real build steps, gotchas, and validation checks
documented as I went.

## What this portfolio demonstrates

- **Business framing** — each build starts from a real-world scenario (multi-tier app,
  hybrid on-prem connectivity, zero-trust internal API), not a services checklist.
- **Security posture** — least-privilege security groups, NACLs, segmented VPCs, and
  zero-trust patterns applied throughout, not bolted on as an afterthought.
- **High availability** — multi-AZ design decisions and their trade-offs, called out
  explicitly in each module rather than assumed.
- **Cost awareness** — NAT Gateway vs. NAT instance, VPC endpoints vs. NAT traffic,
  Direct Connect vs. VPN — the cost reasoning behind design choices, not just "it works."
- **Real troubleshooting** — actual errors hit while building, and how they were
  diagnosed and fixed, kept in each module's Lessons Learned section.

## Modules

| # | Module | Focus |
|---|--------|-------|
| 01 | [VPC Networking Basics](./01-vpc-networking-basics) | CIDR planning, subnets, route tables, IGW |
| 02 | [Secure S3 Static Website](./02-secure-s3-static-website) | S3 + CloudFront security basics |
| 03 | [Multi-Tier App (ALB, ASG, RDS)](./03-multi-tier-app-alb-asg-rds) | Public/private tier separation, load balancing |
| 04 | [Transit Gateway Hub-and-Spoke](./04-transit-gateway-hub-spoke) | Centralized routing across multiple VPCs |
| 05 | [Site-to-Site VPN Lab](./05-site-to-site-vpn-lab) | On-prem to AWS VPN connectivity |
| 06 | [Hybrid Network — Direct Connect](./06-hybrid-network-direct-connect) | Direct Connect architecture and design |
| 07 | [Regional NAT Gateway](./07-aws-regional-nat-gateway) | Outbound internet access for private subnets |
| 08 | [Secure Hybrid Network Capstone](./08-secure-hybrid-network-capstone) | Combined hybrid + security patterns |
| 09 | [Zero Trust Internal API](./09-zero-trust-internal-api) | Zero-trust access to an internal service |

## How each module is documented

Every module folder follows the same five-section format:

1. **Overview** — what's being built and why
2. **Core Components** — the AWS services/resources involved
3. **Build Steps** — the order of operations to reproduce it
4. **Lessons Learned** — real gotchas and debugging notes from building it
5. **Validation Checklist** — how to confirm it actually works

## Tech / Services Covered

VPC · Subnets · Route Tables · IGW · NAT Gateway · Security Groups · NACLs ·
Transit Gateway · Site-to-Site VPN · Direct Connect (design) · ALB · Auto Scaling ·
RDS · CloudFront · VPC Endpoints · CloudWatch

## About

Built and maintained by [Vanchinathan](https://github.com/vanchinathan-Cloud) as a
hands-on record of AWS network engineering work — not a portfolio of screenshots,
but of things actually deployed and validated.
