# Cloud Network Portfolio

A hands-on AWS networking portfolio covering core VPC concepts through hybrid and advanced connectivity patterns. Each module includes an overview, build steps, a validation checklist, and lessons learned from actually building it.

**Skills demonstrated:** VPC Design · Subnetting & Routing · S3 + CloudFront (OAC) · ALB / Auto Scaling / RDS · Transit Gateway · Site-to-Site VPN · Direct Connect · Regional NAT Gateway

---

## Completed Modules

| # | Module | Topic |
|---|--------|-------|
| 01 | [VPC Networking Basics](./01-vpc-networking-basics) | CIDR planning, subnets, route tables, IGW/NAT fundamentals |
| 02 | [Secure S3 Static Website](./02-secure-s3-static-website) | S3 + CloudFront + Origin Access Control, HTTPS, private bucket pattern |
| 03 | [Multi-Tier App (ALB + ASG + RDS)](./03-multi-tier-app-alb-asg) | Three-tier architecture, Auto Scaling, Multi-AZ RDS, security group chaining |
| 04 | [Transit Gateway Hub-and-Spoke](./04-transit-gateway-hub-spoke) | Centralized routing across multiple VPCs, route table segmentation |
| 05 | [Site-to-Site VPN Lab](./05-site-to-site-vpn-lab) | IPsec VPN, Customer/Virtual Private Gateway, static vs. BGP routing |
| 06 | [Hybrid Network — Direct Connect](./06-hybrid-network-direct-connect) | Dedicated fiber connectivity, Direct Connect Gateway, DX vs. VPN tradeoffs |
| 07 | [AWS Regional NAT Gateway](./07-aws-regional-nat-gateway) | Newer VPC-wide NAT pattern (2025+), Regional vs. Zonal NAT comparison |

## Planned / Upcoming Modules

| # | Module | Status |
|---|--------|--------|
| 08 | AWS Network Firewall | Planned |
| 09 | Gateway Load Balancer | Planned |
| 10 | CloudFront + Global Accelerator | Planned |
| 11 | Route 53 Failover Routing | Planned |
| 12 | VPC Endpoints (Private Access) | Planned |
| 13 | Multi-Region Disaster Recovery | Planned |
| 14 | Enterprise Network Reference Architecture | Planned |

> **Note:** "VPC Peering — Cross Region" and "Highly Available NAT Gateway" from the original roadmap were superseded — VPC Peering concepts are covered within the Transit Gateway module, and NAT HA is now covered by the Regional NAT Gateway module (07), which replaces the older per-AZ pattern.

---

## How Each Module Is Structured

Every module folder follows the same format:
- **Overview** — what's being built and why
- **Core Components** — the AWS services/resources involved
- **Build Steps** — the order of operations to reproduce it
- **Lessons Learned** — real gotchas and debugging notes from building it
- **Validation Checklist** — how to confirm it actually works

## About This Portfolio

Built to demonstrate practical, hands-on AWS networking skills — from foundational VPC design through advanced hybrid connectivity — with an emphasis on documenting *why* each pattern is used, not just the console clicks to build it.