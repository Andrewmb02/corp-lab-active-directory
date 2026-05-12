# 02 — Domain Controller Deployment

## Goal

Deploy a Windows Server 2025 VM, install the Active Directory Domain 
Services role, and promote it to be the first domain controller of a new 
forest called `corp.local`.

## VM Configuration

| Setting | Value |
|---------|-------|
| Name | DC01 |
| Size | Standard_B2ms (2 vCPU, 8 GiB RAM) |
| Image | Windows Server 2025 Datacenter: Azure Edition - x64 Gen2 |
| Security type | Standard (not Trusted Launch — avoids AD complications) |
| OS disk | Standard SSD LRS |
| Private IP | 10.0.1.4 (static) |
| Public IP | Yes, for initial setup access |
| NSG | ad-nsg attached at NIC level |
| Auto-shutdown | 11 PM Eastern |
| Public ports exposed | None at provisioning (NSG handles RDP) |

## Why Standard_B2ms

The B2ms size (8 GB RAM) gives the domain controller comfortable headroom 
for AD DS, DNS, and the various supporting services. The B2s size (4 GB) 
would technically work but Windows Server 2025 plus AD operations would 
constrain memory during operations like installations and Group Policy 
processing.

## Why Static Private IP

Domain controllers require stable IP addresses. Azure's "static" assignment 
within DHCP guarantees the same IP across reboots. Setting this at the 
Azure NIC level (not within the OS) is critical — overriding inside 
Windows breaks Azure's networking.

## Deployment Sequence

1. **Create VM** through Azure Portal with above settings
2. **Set private IP to static** (10.0.1.4) via NIC IP configurations
3. **RDP in** as local admin (.\labadmin)
4. **Install AD DS role** via PowerShell:

\`\`\`powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
\`\`\`

5. **Promote to domain controller** creating new forest:

\`\`\`powershell
Install-ADDSForest \`
    -DomainName "corp.local" \`
    -DomainNetbiosName "CORP" \`
    -InstallDns \`
    -Force
\`\`\`

This prompts for a DSRM (Directory Services Restore Mode) password. The 
DSRM password is intentionally separate from the domain admin password — 
keeping them distinct is a security best practice that prevents a 
compromised domain admin credential from also granting access to the 
recovery environment.

6. **VM reboots automatically** when promotion completes
7. **Verify domain is operational**:

\`\`\`powershell
Get-ADDomain | Select Name, Forest, DomainMode
Get-ADDomainController | Select Name, Domain, IPv4Address
\`\`\`

## Expected Output

\`\`\`
Name    Forest      DomainMode
----    ------      ----------
corp    corp.local  Windows2025Domain

Name    Domain      IPv4Address
----    ------      -----------
DC01    corp.local  10.0.1.4
\`\`\`

## Why PowerShell Over GUI

The Server Manager GUI promotion wizard works but is more brittle: it 
sometimes requires a reboot between role install and promotion, the 
wizard can fail prerequisites checks for environmental reasons, and the 
clicks are easy to misremember. The PowerShell approach is:

- One command per phase
- Self-documenting (you can see exactly what was done)
- Repeatable for any future DC deployment
- The same method real admins use in production

## Troubleshooting Notes

If the promotion wizard reports "Role change is in progress or this 
computer needs to be restarted" — the AD DS role install didn't fully 
finalize. Reboot the VM and try the promotion again. This is a known 
behavior, not an error in your setup.

If you see DNS delegation warnings during promotion ("authoritative parent 
zone cannot be found") — this is expected and harmless for an isolated 
lab domain. There is no public DNS authority for `corp.local`, by design.
