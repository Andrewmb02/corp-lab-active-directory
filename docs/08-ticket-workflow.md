# 08 — Ticket-Based Incident Response Workflow

## Goal

Demonstrate the full IT support workflow using an industry-standard 
ticketing system. Practice the discipline of identity verification, 
documentation, escalation, and proper closure.

## System Used

**osTicket 1.18.2** — self-hosted on Ubuntu Server 24.04 in Azure, with a LAMP stack (Apache, MariaDB, PHP 8.3). Authentication is integrated with the corp.local Active Directory via encrypted LDAPS, demonstrating end-to-end identity federation between Linux and Windows.

The original lab plan called for Spiceworks Cloud Help Desk for time-efficiency. The decision to migrate to a self-hosted osTicket deployment added genuine Linux administration, PKI deployment, and cross-region Azure networking to the demonstrated skill set.

See `docs/10-osticket-deployment.md` for the deployment details and `docs/11-cross-region-ad-integration.md` for the AD integration architecture.

### Why osTicket vs Spiceworks Cloud

| Aspect | Spiceworks Cloud | osTicket (chosen) |
|---|---|---|
| Hosting | SaaS | Self-hosted on Ubuntu |
| Cost | Free | Free + Azure VM (~$7/mo) |
| Authentication | Standalone | LDAPS-integrated with corp.local AD |
| Skills demonstrated | Configuration only | Linux admin, LAMP stack, PKI, cross-region networking, LDAP integration |
| Realism | Small business pattern | Mid-size enterprise pattern |

## Standard Ticket Workflow

Every ticket follows this lifecycle:

1. **Receive** — ticket submitted via portal, email, or phone
2. **Acknowledge** — respond within SLA so user knows it's seen
3. **Categorize & Prioritize** — P1 (system down) through P4 (request)
4. **Verify Identity** — especially for password/access tickets
5. **Investigate** — gather info, reproduce, check logs
6. **Resolve or Escalate** — fix if within scope, escalate if not
7. **Document** — what was the issue, what was the fix, prevention
8. **Close** — confirm with user before closing

## Tier Structure

| Tier | Scope | Examples |
|------|-------|----------|
| L1 / Help Desk | Common user issues | Password resets, lockouts, simple software |
| L2 / Support Specialist | Deeper troubleshooting | AD/GPO issues, app errors, network |
| L3 / Sysadmin | Infrastructure | Server issues, config changes, RCA |
| Vendor | Outside company scope | Microsoft Premier, vendor support |

## Documented Ticket Scenarios

The lab includes seven documented ticket scenarios covering the most 
common L1 IT support situations:

### Ticket Categories Covered

| Category | Scenarios | Skills Demonstrated |
|----------|-----------|---------------------|
| Password Reset | Forgot password | Identity verification, ADUC reset workflow |
| Account Lockout | Multiple failed logins | Account tab review, unlock procedure |
| Access Request | Department resource access | Group management, approval workflow |
| New Hire | Onboarding new employee | User provisioning, group assignment |
| Termination | Immediate deprovisioning | Security-first response, audit trail |
| VPN/Remote Access | Authentication issues | Diagnostic methodology, user education |
| Multi-User Issue | Domain-wide impact | Escalation procedure, handoff documentation |

## Identity Verification Discipline

The most important habit demonstrated in this workflow: **never reset a 
password or grant access without verifying the requester's identity** 
through a separate channel from how they made the request.

Standard verification methods:
- Callback to the user's listed phone number
- Verification of employee ID against directory
- Confirmation through user's manager (for sensitive changes)
- Security questions (when applicable)

This discipline prevents social engineering attacks where an attacker 
submits a help desk ticket claiming to be a target user.

## Escalation Documentation

When escalating to L2, the handoff documentation includes:

- **Affected users** (specific list, not "a few")
- **Common pattern** (what links them)
- **What was ruled out** (so L2 doesn't repeat your work)
- **What is suspected** (your best hypothesis based on evidence)
- **Time to resolve so far** (helps L2 prioritize)

Good escalation documentation is a force multiplier — bad escalation 
just shifts the problem without progressing it.

## Compliance Considerations

Several tickets demonstrate HIPAA-adjacent thinking even in a non-PHI lab:

- **Terminations require fast revocation** (HIPAA Security Rule)
- **MFA reset for lost devices** requires extra verification
- **Audit trail preserved** when removing users from groups (don't delete 
  the user object immediately)
- **Manager approval workflow** for cross-department access

These habits transfer directly to real healthcare IT environments.

