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

## 🎯 Explain

I deploy SD-WAN edges (cEdge) at branches.

They build IPSec tunnels over the internet to AWS using AWS Site-to-Site
VPN, terminating on AWS Transit Gateway.

Transit Gateway routes traffic to the appropriate Amazon VPC.

For application distribution, I use Elastic Load Balancing.

## 🧱 Build Steps

1. Provision cEdge devices at each branch and onboard them to the SD-WAN
   controller (Cisco vManage).
2. Create an AWS Transit Gateway and a Site-to-Site VPN attachment per
   branch, using a dedicated tunnel-inside CIDR for each of the two tunnels
   (dual-tunnel HA — see Key Points below).
3. Attach the target VPC to the Transit Gateway.
4. Configure a Transit Gateway route table that sends branch-originated
   traffic to the VPC attachment, and VPC-originated return traffic back to
   the correct VPN attachment.
5. Deploy an Application Load Balancer in the VPC's public subnets, with
   targets in private subnets.
6. Define an SD-WAN centralized policy that marks/prioritizes application
   traffic destined for the AWS prefix before it enters the IPSec tunnel.

## 🔥 Key Points to Mention

- **BGP** is used for route exchange between the cEdge and the AWS VPN
  endpoint — no static routes to maintain as VPCs change.
- **Dual tunnels** per branch (to two Transit Gateway VPN endpoints) provide
  HA — if one tunnel or AWS-side endpoint fails, BGP reconverges onto the
  surviving tunnel automatically.
- **SD-WAN policy** controls which traffic is even allowed to take the AWS
  path — only business-critical/app traffic classes are steered to the
  tunnel; guest/best-effort traffic breaks out locally to the internet
  instead.
