# 01 — Azure Infrastructure Foundation

## Goal

Build the foundational Azure infrastructure that will host the Active 
Directory lab: resource group, virtual network, subnet, and a Network 
Security Group enforcing restricted RDP access.

## Design Decisions

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Region | East US | Lowest latency from US East Coast; broad service availability |
| Address space | 10.0.0.0/16 | Standard private RFC1918 space, room for growth |
| Subnet | 10.0.1.0/24 | Single subnet sufficient for lab; 254 usable IPs |
| RDP exposure | Home IP only | Reduces attack surface vs. open 3389 to internet |
| Bastion/Firewall | Not used | $140-900/month enterprise services overkill for lab |

## Components Deployed

### Resource Group: `ad-lab`

Container for all lab resources. Allows single-click cleanup when lab 
is decommissioned. All resources live within this one resource group.

### Virtual Network: `ad-vnet`

- Address space: `10.0.0.0/16`
- Single subnet: `ad-subnet` at `10.0.1.0/24`
- Bastion, Firewall, and DDoS Protection: disabled (cost reasons)

### Network Security Group: `ad-nsg`

Custom inbound rule restricting RDP to home IP only:

| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | Allow-RDP-FromHome | [Home IP] | Any | 3389 | TCP | Allow |
| 65000 | AllowVnetInBound | VirtualNetwork | VirtualNetwork | Any | Any | Allow |
| 65001 | AllowAzureLoadBalancer | AzureLoadBalancer | Any | Any | Any | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | Any | Deny |

The custom rule sits at priority 100 — evaluated first. All other internet 
traffic falls through to the default DenyAllInBound at 65500.

## Security Philosophy

Rather than enabling expensive enterprise services (Azure Bastion at 
~$140/month, Azure Firewall at ~$900/month), this lab achieves appropriate 
security through:

1. **Restrictive NSG rules** — RDP only from a single source IP
2. **Strong VM admin passwords** — 14+ character complex passwords
3. **Resource group isolation** — entire lab contained, easy cleanup
4. **Auto-shutdown schedules** — VMs not running 24/7 attracting attention
5. **No services exposed beyond RDP** — single attack vector to defend

This represents a layered defense appropriate to the threat model: a 
single-user lab where the user controls their own source IP.

## Cost Considerations

Standalone Azure infrastructure costs (excluding VMs):
- VNet/subnet: free
- NSG: free
- Public IPs (per VM): ~$0.005/hour each

Monthly base infrastructure cost when VMs deallocated: under $5.
