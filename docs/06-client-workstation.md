# 06 — Client Workstation Deployment and Domain Join

## Goal

Deploy a Windows Server 2025 VM serving as a workstation, configure DNS 
to point at the domain controller, and join it to the corp.local domain.

## Why Windows Server as Client

Azure Student subscriptions cannot deploy Windows 11 client images due 
to licensing restrictions — the spending limit on student accounts is 
incompatible with Windows desktop OS licensing in Azure.

Windows Server 2025 substitutes effectively for a Windows 11 client in 
this lab because:

- Domain join behavior is identical
- Group Policy application is identical
- File share access works the same way
- RDP, PowerShell, File Explorer all function the same
- It's more aligned with real enterprise IT work, where security tooling 
  often targets server-class endpoints

For interview discussions: this is also the right choice for scaling the 
lab. Multiple "client" VMs can be deployed without licensing friction, 
and the entire setup transfers 1:1 to a future home lab on Proxmox or 
ESXi.

## VM Configuration

| Setting | Value |
|---------|-------|
| Name | CLIENT01 |
| Size | Standard_B2s (2 vCPU, 4 GiB RAM) |
| Image | Windows Server 2025 Datacenter |
| Security type | Standard |
| OS disk | Standard SSD LRS |
| Public IP | Yes (for initial setup) |
| NSG | ad-nsg (same as DC01) |
| Auto-shutdown | 11 PM Eastern |

## DNS Configuration (Critical Step)

Domain join fails if the client cannot resolve the domain via DNS. The 
client must use the domain controller as its DNS server.

**Via PowerShell:**
```powershell
# Identify network adapter
Get-NetAdapter

# Set DC01 as primary DNS server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.0.1.4

# Verify resolution works
Resolve-DnsName corp.local
```

**Via GUI:**
1. Win+R → `ncpa.cpl` → Enter
2. Right-click Ethernet adapter → Properties
3. Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties
4. Select "Use the following DNS server addresses"
5. Preferred DNS: `10.0.1.4` (DC01's private IP)
6. Verify with `nslookup corp.local`

## Domain Join

**Via PowerShell:**
```powershell
Add-Computer -DomainName "corp.local" -Credential (Get-Credential) -Restart
```

Prompts for credentials of a user with domain join rights (any Domain 
Admin, e.g., `CORP\labadmin`). VM reboots automatically on success.

**Via GUI:**
1. Win+R → `sysdm.cpl` → Enter
2. Computer Name tab → Change...
3. Member of: Domain → type `corp.local` → OK
4. Provide domain admin credentials
5. Welcome message confirms successful join
6. Restart when prompted

## Post-Join Configuration: RDP Authorization

By default, only members of the local Administrators group can RDP into 
a Windows machine. Domain users get "The connection was denied because 
the user account is not authorized for remote login" until added to the 
local Remote Desktop Users group.

**Fix:**
```powershell
# On CLIENT01, as local administrator:
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CORP\All-Employees"
```

This grants RDP access to all domain users (via All-Employees membership) 
without making them administrators.

In production, this would typically be:
- Deployed via Group Policy Restricted Groups setting
- Use a more specific group like "Remote Workers" rather than All-Employees
- Combined with conditional access rules (time, location, MFA)

## Verification

After join and reboot, logging in as a domain user demonstrates the full 
chain working:

1. RDP to CLIENT01 with `CORP\<username>` credentials
2. Logon banner appears (proves GPO is applied)
3. User authenticates against DC01
4. Profile created on first login
5. User can access network resources based on group memberships

## What This Proves

A successful login as a regular domain user from a workstation joined 
to the domain demonstrates:

- Active Directory is operational
- DNS is correctly configured
- Domain trust is established
- Group Policy is applied
- Authentication flows end-to-end
- Authorization works (user can access permitted resources)

This is the foundation that everything else in the lab builds on.
