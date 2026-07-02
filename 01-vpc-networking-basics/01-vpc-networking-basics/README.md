This project demonstrates the fundamentals of building a production-ready AWS VPC from scratch.  
A VPC is a virtual network that closely resembles a traditional network that you'd operate in your own data center.
Virtual Private Clouds (VPCs) are regional-specific.
VPCs are isolated networks.
Each region comes with a default VPC - can be deleted ( One default VPC per Region ).
Each region can have multiple VPCs -Max 5 VPC's inculding default VPC (Soft limit) per region.
It includes public and private subnets across multiple AZs, route tables, IGW/NAT design, and VPC Flow Logs.  
The goal is to understand traffic flow, subnet isolation, and core AWS networking concepts used in real architectures.(refter the sample architeture-digaram)

# 01 - AWS VPC Networking Basics

## Project Overview

This project demonstrates the core networking components of an Amazon Virtual Private Cloud (VPC). It provides a foundational understanding of AWS networking by creating a secure and scalable network with public and private subnets.

---

## Architecture

```text
                    Internet
                        │
                Internet Gateway
                        │
                +----------------+
                |      VPC       |
                |   10.0.0.0/16  |
                +----------------+
                 │             │
        Public Subnet     Private Subnet
        10.0.1.0/24       10.0.2.0/24
             │                 │
          EC2 Instance     EC2 Instance
             │                 │
          NAT Gateway  <────────┘
```

---

## AWS Services Used

- Amazon VPC
- Public Subnet
- Private Subnet
- Internet Gateway (IGW)
- NAT Gateway
- Route Tables
- Security Groups
- Network ACLs
- Amazon EC2
- Elastic IP

---

## Project Objectives

- Create a custom Amazon VPC.
- Configure public and private subnets.
- Enable internet access using an Internet Gateway.
- Provide outbound internet access for private resources using a NAT Gateway.
- Configure route tables for public and private traffic.
- Secure resources using Security Groups and Network ACLs.

---

## Deployment Steps

1. Create a VPC (10.0.0.0/16).
2. Create one public subnet.
3. Create one private subnet.
4. Attach an Internet Gateway to the VPC.
5. Allocate an Elastic IP and create a NAT Gateway.
6. Create public and private route tables.
7. Associate route tables with the appropriate subnets.
8. Launch EC2 instances.
9. Configure Security Groups.
10. Verify internet connectivity.

---


## Validation

- Verify the public EC2 instance has internet access.
- Verify the private EC2 instance accesses the internet through the NAT Gateway.
- Confirm route table associations.
- Validate Security Group and Network ACL rules.
- Test connectivity between public and private instances.

---

## Learning Outcomes

After completing this lab, you will understand:

- Amazon VPC architecture
- CIDR block planning
- Public vs. Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Security Groups
- Network ACLs
- Elastic IPs
- Basic AWS networking best practices

---

## Best Practices

- Use private subnets for application and database servers.
- Restrict inbound access with Security Groups.
- Enable least-privilege access.
- Deploy resources across multiple Availability Zones for high availability.
- Use Infrastructure as Code (Terraform or CloudFormation) where possible.

---

## Future Enhancements

- Multi-AZ VPC design
- VPC Flow Logs
- Transit Gateway integration
- VPC Endpoints
- Site-to-Site VPN
- AWS Network Firewall


- Cisco Enterprise Networking
- Cisco SD-WAN
- Hybrid Cloud Networking
