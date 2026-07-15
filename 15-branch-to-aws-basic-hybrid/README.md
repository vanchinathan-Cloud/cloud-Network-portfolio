# Module 15: Branch to AWS via SD-WAN (Basic Hybrid)

```
 Branch1         Branch2
   |               |
 [cEdge]         [cEdge]
    \             /
     \           /
      ---- Internet ----
              |
        IPSec Tunnel
              |
     -------------------
     |                 |
     |   Transit GW    |
     |                 |
     -------------------
              |
          [VPC]
              |
     App / Load Balancer
```

## Overview

This module builds the most fundamental hybrid connectivity pattern between
enterprise branch sites and AWS: two branches, each with a Cisco SD-WAN
edge (cEdge), reaching a shared AWS environment over the public internet
via IPSec. It's the pattern I use as the starting point for any MPLS → 
SD-WAN → Cloud migration — before adding HA regions, Direct Connect
backup, or segmentation, this is the baseline that has to work first.

The goal is straightforward: get branch traffic into a VPC reliably, using
dynamic routing (not static routes that break the moment the VPC changes),
and expose the application behind a load balancer rather than a single
instance.

## Core Components

| Component | Role |
|---|---|
| **Cisco cEdge (SD-WAN edge)** | Deployed at each branch; builds the IPSec tunnel(s) toward AWS and enforces SD-WAN policy on what traffic is allowed to use that path |
| **AWS Site-to-Site VPN** | Terminates the branch IPSec tunnels on the AWS side |
| **AWS Transit Gateway** | Central routing hub that receives the VPN attachments and routes traffic into the correct VPC |
| **BGP** | Runs over the IPSec tunnels between cEdge and the AWS VPN endpoint for dynamic route exchange |
| **Amazon VPC** | Hosts the application environment the branches need to reach |
| **Application Load Balancer (ALB)** | Distributes incoming branch traffic across the application tier inside the VPC |

## Build Steps

1. **Provision the cEdge devices** at Branch1 and Branch2, and onboard both
   to the SD-WAN controller (Cisco vManage).
2. **Create the Transit Gateway** in the target AWS region.
3. **Create two Site-to-Site VPN connections** (one per branch) attached to
   the Transit Gateway. Each VPN connection gets two tunnels by default —
   this dual-tunnel behavior is what provides HA per branch.
4. **Configure BGP** on each cEdge to peer with the corresponding AWS VPN
   tunnel endpoints, advertising the branch-side prefixes and learning the
   VPC prefix in return.
5. **Attach the target VPC** to the Transit Gateway.
6. **Build the Transit Gateway route table** so that traffic from each VPN
   attachment is routed to the VPC attachment, and VPC-originated return
   traffic is routed back to the correct VPN attachment per branch.
7. **Deploy the ALB** in the VPC's public subnets, with targets (EC2
   instances or an Auto Scaling Group) in private subnets.
8. **Apply SD-WAN centralized policy** on the controller so only the
   intended traffic classes (e.g., business-critical, application traffic)
   are steered toward the AWS-bound tunnel — not all branch traffic by
   default.
9. **Test connectivity** end-to-end from a host at each branch to the ALB's
   DNS name, and confirm both tunnels show as "UP" in the AWS VPN console.

## Lessons Learned

- **The tunnel-inside CIDR ranges must be unique per VPN connection.** If
  two branches' VPN connections are built with overlapping
  tunnel-inside `/30` ranges, BGP peering silently fails on one side —
  this is easy to miss because the tunnel itself shows as "UP" while
  routing simply never converges.
- **Both tunnels need to be actually configured on the cEdge, not just
  the primary.** It's tempting to wire up only the first tunnel and treat
  the second as "spare capacity for later" — but then the HA benefit
  doesn't exist until a real failure forces you to configure it under
  pressure. Build both from day one.
- **SD-WAN policy is a separate control from routing.** Getting BGP to
  converge does not mean traffic is actually being steered the way you
  intended — a centralized policy that doesn't explicitly match the
  AWS-bound prefix will let traffic fall through to a default route
  (often local internet breakout), which looks like a routing problem but
  is actually a policy gap.
- **Transit Gateway route table associations vs. propagations are easy to
  confuse.** An attachment can be associated with a route table without
  its routes being propagated into it, which results in one-directional
  reachability that's confusing to troubleshoot without checking both
  settings explicitly.
- **ALB health checks need a real path, not just a port check.** Early
  testing with a TCP-only health check showed the ALB as healthy even
  when the actual application endpoint was returning errors — switching
  to an HTTP health check against the real app path caught this
  immediately.

## Validation Checklist

- [ ] Both IPSec tunnels per branch show **UP** in the AWS VPN console
- [ ] BGP session state is **Established** on each cEdge, for each tunnel
- [ ] The VPC prefix appears in the cEdge's routing table, learned via BGP
- [ ] The branch prefix appears in the Transit Gateway route table,
      pointing to the correct VPN attachment
- [ ] Traceroute from a branch host to the ALB shows the expected path
      (branch → IPSec tunnel → Transit Gateway → VPC)
- [ ] Killing the primary tunnel (admin shutdown) causes traffic to fail
      over to the secondary tunnel with no manual intervention
- [ ] SD-WAN policy hit counters show the expected traffic classes being
      matched and steered toward the AWS tunnel
- [ ] ALB target group shows all targets as **healthy**
- [ ] End-to-end application request from each branch succeeds and
      resolves to the ALB's DNS name
