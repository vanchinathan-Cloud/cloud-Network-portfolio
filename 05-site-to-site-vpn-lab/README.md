# 05 — Site-to-Site VPN Lab

![Architecture Diagram](./architecture-diagram.svg)

## Overview
This lab simulates a hybrid connection between an on-premises network and AWS using an IPsec Site-to-Site VPN. Since a physical on-prem router/firewall isn't available, a second VPC (or a software router like strongSwan/OpenSwan on an EC2 instance) stands in as the "on-prem" side.

If this follows on from the Transit Gateway module, the VPN can attach either directly to a VPC (Virtual Private Gateway) or to the Transit Gateway as another spoke — extending the hub-and-spoke topology to include on-prem.

Full walkthrough: [AWS_Site-to-Site VPN Setup.docx](./AWS_Site-to-Site%20VPN%20Setup.docx)

## Core Components

| Component | Purpose |
|---|---|
| **Customer Gateway (CGW)** | Represents the on-prem side — its public IP and BGP ASN (if using dynamic routing). |
| **Virtual Private Gateway (VGW) or Transit Gateway (TGW)** | The AWS side termination point. VGW attaches to a single VPC; TGW lets the VPN act as one more spoke alongside your other VPCs. |
| **Site-to-Site VPN Connection** | The actual IPsec tunnel(s) between CGW and VGW/TGW — AWS creates two tunnels for redundancy. |
| **Routing (static or BGP/dynamic)** | Determines how routes are exchanged — static CIDR entries, or BGP if the on-prem device supports it. |
| **On-prem simulator** | EC2 instance running strongSwan/Libreswan, or a second VPC with a software VPN appliance, standing in for a real on-prem router. |

### Two Ways to Terminate the VPN
1. **VPN → Virtual Private Gateway (VGW) → single VPC** — Simple, classic setup. Good for a single VPC use case.
2. **VPN → Transit Gateway → multiple spoke VPCs** — Preferred when you already have a hub-and-spoke setup (like Module 04) — the VPN becomes just another TGW attachment, so on-prem gets the same routed access as any spoke, controlled through TGW route tables.

### Static vs. BGP (Dynamic) Routing
- **Static routing:** you manually declare on-prem CIDR blocks in the VPN connection config. Simple, but any change on-prem requires a manual update.
- **BGP routing:** on-prem router peers via BGP over the tunnel and advertises/receives routes automatically. More resilient, standard for production, but requires a device that supports BGP (strongSwan can with a BGP daemon like bird or FRRouting).

## Build Steps

1. **Stand up the "on-prem" side** — Either a real on-prem simulator (EC2 + strongSwan) with its own public IP, or use AWS's own second VPC/CGW for practice.
2. **Create a Customer Gateway (CGW) in AWS** — Provide the on-prem public IP and BGP ASN (if dynamic).
3. **Create the AWS-side termination point** — A Virtual Private Gateway attached to the target VPC, or reference the existing Transit Gateway.
4. **Create the Site-to-Site VPN Connection** — Choose static routing (manually list on-prem CIDRs) or dynamic (BGP). AWS returns a configuration file with two tunnel endpoints, PSKs, and settings — download it (there's a template for many vendors, including generic/strongSwan).
5. **Configure the on-prem/simulator side** — Apply the downloaded config to strongSwan/Libreswan (IKE version, PSK, encryption/DH settings, tunnel IPs). Bring the IPsec tunnel up and confirm Tunnel Status = UP in the AWS console.
6. **Enable route propagation / add static routes**
   - VGW path: enable route propagation on the VPC route table so AWS learns on-prem CIDRs automatically (if BGP), or add static routes.
   - TGW path: propagate the VPN attachment's routes into the relevant TGW route table, same as any other spoke.
7. **Update security groups / NACLs** to allow the expected traffic (e.g., ICMP for testing, plus real app ports) between on-prem and AWS CIDR ranges.
8. **Test connectivity** — ping/traceroute from an instance in the on-prem simulator to an instance in the AWS VPC, and vice versa.

## Lessons Learned

- Tunnels stay down until traffic is initiated in some setups — AWS VPN tunnels can show "DOWN" until traffic actually starts flowing; don't assume it's broken just because it's idle.
- Both tunnels matter — AWS gives you two tunnel endpoints for HA; configure both on the on-prem side, not just one, or you lose redundancy.
- PSK and IKE parameters must match exactly on both ends — mismatched encryption/DH group/IKE version is the most common cause of a tunnel that never comes up.
- CIDR overlap between "on-prem" and AWS VPC breaks routing — as with TGW, ranges must be unique.
- NAT/firewall in front of the on-prem simulator can block IPsec (UDP 500/4500, ESP protocol 50) — make sure those are open.
- Route propagation must be enabled explicitly on the VPC route table (or TGW route table) — creating the VPN connection alone doesn't add routes automatically unless propagation is turned on.
- If layering onto Transit Gateway from Module 04, remember the VPN attachment needs to be associated/propagated into the correct TGW route table just like a VPC spoke.

## Validation Checklist

- [ ] Both VPN tunnels show UP in the AWS console
- [ ] VPC/TGW route table shows the propagated on-prem CIDR
- [ ] Instance in AWS can ping instance in on-prem simulator
- [ ] Instance in on-prem simulator can ping instance in AWS
- [ ] Traffic actually traverses the tunnel (check VPNTunnel CloudWatch metrics — TunnelState, TunnelDataIn/TunnelDataOut)
- [ ] Failover test: bring down Tunnel 1, confirm Tunnel 2 keeps traffic flowing
