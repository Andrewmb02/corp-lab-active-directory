# 05 — Group Policy: Corporate Logon Banner

## Goal

Author a Group Policy Object that enforces a corporate logon banner on 
all domain-joined machines. Demonstrates GPO authoring, linking, 
deployment, and verification.

## Why a Logon Banner

Logon banners serve two purposes in enterprise environments:

1. **Legal disclaimer** — notifies users they are accessing a private 
   system and consent to monitoring. Strengthens the organization's 
   position in security incidents and legal proceedings.

2. **Compliance requirement** — in healthcare environments specifically, 
   HIPAA Security Rule requires demonstration of access controls and 
   user awareness. A logon banner is often part of meeting that 
   compliance posture.

## GPO Details

| Property | Value |
|----------|-------|
| GPO Name | Corporate Logon Banner |
| Linked to | corp.local (domain root) |
| Scope | All computers in domain |
| Applied at | Boot / pre-logon |
| Settings location | Computer Configuration → Windows Settings → Security Settings → Local Policies → Security Options |

## Settings Configured

**Interactive logon: Message title for users attempting to log on:**
\`\`\`
Corporate System — Authorized Access Only
\`\`\`

**Interactive logon: Message text for users attempting to log on:**
\`\`\`
This system is the property of corp.local and is for authorized 
business use only.

All activity on this system may be monitored and recorded for security 
and compliance purposes.

Unauthorized access or misuse may result in disciplinary action, 
termination, civil liability, and/or criminal prosecution.

By logging in, you consent to these terms.
\`\`\`

## Deployment

1. Open Group Policy Management Console (`gpmc.msc`)
2. Right-click `corp.local` → "Create a GPO in this domain, and Link it 
   here..."
3. Name: `Corporate Logon Banner`
4. Right-click new GPO → Edit
5. Navigate to: Computer Configuration → Policies → Windows Settings → 
   Security Settings → Local Policies → Security Options
6. Configure both the Message title and Message text settings
7. Close editor
8. Force immediate policy refresh: `gpupdate /force`

## Verification

The banner is verified on the next interactive logon to any domain-joined 
machine. In this lab, the banner was verified by logging into CLIENT01 
as a domain user — the banner displayed before the Windows desktop loaded.

GPOs typically refresh every 90 minutes (with a random 30-minute offset) 
on member computers. For immediate testing, `gpupdate /force` on the 
client pulls the policy on demand.

## Production Considerations

In production, this GPO would typically:
- Be linked at the domain root (as done here) for universal coverage
- Be coordinated with Legal/Compliance teams for exact wording
- Include version date in the message text to track policy updates
- Be tested in a pilot OU before domain-wide deployment

## Other GPOs Worth Adding (Future Work)

- **Password policy** — minimum length, complexity, history
- **Account lockout policy** — threshold, duration, reset window
- **Screen lock timer** — auto-lock after 5-15 minutes of inactivity
- **USB device restrictions** — block removable storage on sensitive 
  workstations
- **Audit policy** — enable detailed logon/logoff auditing for SIEM 
  forwarding
- **Software restriction** — block unapproved applications

Each represents a real security control that compounds the security 
posture of the environment.
