<#
.SYNOPSIS
    Configures Windows Firewall on DC01 to allow AD-related traffic from
    the ticket-vnet (10.1.0.0/16) in East US 2.
 
.DESCRIPTION
    Adds five inbound allow rules scoped to the ticket-vnet subnet:
    - DNS (UDP 53)
    - DNS (TCP 53, for large query responses)
    - LDAP (TCP 389) — legacy port, retained for compatibility
    - LDAPS (TCP 636) — primary auth path
    - Global Catalog (TCP 3268, 3269) — for forest-wide queries
 
    Each rule restricts the source to 10.1.0.0/16 so random internet
    traffic cannot reach these ports even though they're open on the host.
 
.NOTES
    Run as Administrator on DC01.
    Idempotent on the rule names — re-running will error if rules exist;
    use Get-NetFirewallRule -DisplayName "*ticket-vnet*" to verify.
 
.EXAMPLE
    .\dc01-firewall-rules.ps1
#>
 
[CmdletBinding()]
param()
 
$ErrorActionPreference = "Stop"
 
# Verify running as admin
$current = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($current)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "This script must be run as Administrator."
}
 
Write-Host "Adding firewall rules to allow ticket-vnet (10.1.0.0/16) traffic..." -ForegroundColor Cyan
 
$rules = @(
    @{
        Name     = "Allow DNS UDP from ticket-vnet"
        Protocol = "UDP"
        Port     = 53
        Purpose  = "DNS queries from Linux clients"
    },
    @{
        Name     = "Allow DNS TCP from ticket-vnet"
        Protocol = "TCP"
        Port     = 53
        Purpose  = "DNS queries with large responses"
    },
    @{
        Name     = "Allow LDAP from ticket-vnet"
        Protocol = "TCP"
        Port     = 389
        Purpose  = "Legacy LDAP (retained for compatibility, prefer LDAPS)"
    },
    @{
        Name     = "Allow LDAPS from ticket-vnet"
        Protocol = "TCP"
        Port     = 636
        Purpose  = "Encrypted LDAP authentication"
    },
    @{
        Name     = "Allow Global Catalog from ticket-vnet"
        Protocol = "TCP"
        Port     = "3268,3269"
        Purpose  = "Forest-wide AD queries"
    }
)
 
foreach ($r in $rules) {
    try {
        New-NetFirewallRule `
            -DisplayName $r.Name `
            -Direction Inbound `
            -Protocol $r.Protocol `
            -LocalPort $r.Port `
            -RemoteAddress 10.1.0.0/16 `
            -Action Allow | Out-Null
 
        Write-Host "  + Added: $($r.Name) ($($r.Protocol)/$($r.Port)) — $($r.Purpose)" `
            -ForegroundColor Green
    }
    catch {
        Write-Host "  ! Failed to add '$($r.Name)': $_" -ForegroundColor Red
    }
}
 
Write-Host ""
Write-Host "Firewall configuration complete." -ForegroundColor Cyan
Write-Host "Verify rules with: Get-NetFirewallRule -DisplayName '*ticket-vnet*'" `
    -ForegroundColor Yellow
