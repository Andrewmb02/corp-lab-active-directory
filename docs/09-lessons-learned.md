# 09 — Lessons Learned

## Honest Reflections from Building This Lab

This document captures the gotchas, mistakes, and insights from the build 
process. It's the file most worth reading for anyone trying to build a 
similar lab and being able to answer to "what was the most challenging aspect
of this lab?" and being able to expand on this.

## Permission Inheritance Caught Me

The single biggest mistake I made was applying file permissions to the 
parent `C:\Shares` folder by accident instead of the specific subfolder. 
Because NTFS uses inheritance by default, those permissions propagated to 
every subfolder — which meant Sales-Team had access to the parent, and 
inheritance was carrying it everywhere.

**The fix:**
1. Audited permissions with PowerShell to spot the leak
2. Disabled inheritance on the parent and cleaned it
3. Made each subfolder's permissions explicit (not inherited)

**What I learned:** Permission sprawl is the #1 file server problem in 
real enterprises. Catching it requires deliberate auditing, not just 
trusting the GUI to show you what's important. The screenshots looked 
right at a glance — only running the audit script revealed the actual 
permission tree.

## Azure for Students Has Restrictions I Hadn't Anticipated

Windows 11 client images cannot be deployed on Azure Student subscriptions 
due to licensing constraints. The error message points at the spending 
limit, which is intentional — Windows desktop OS licensing in Azure 
requires a Pay-As-You-Go subscription without spending caps.

**The pivot:** Used Windows Server 2025 as the workstation instead.

**What I learned:** Cloud provider tier limitations affect what you can 
do. The workaround (Server as client) actually turned out to be better 
for the lab because it scales without licensing friction and aligns 
more closely with the enterprise tooling I'd want to add later.

## RDP Access for Domain Users Isn't Automatic

After joining CLIENT01 to the domain, regular domain users couldn't RDP 
in — only local administrators could. The error message "The connection 
was denied because the user account is not authorized for remote login" 
isn't a credential failure, it's an authorization failure at the 
RDP-acceptance layer.

**The fix:** Added domain group to the local Remote Desktop Users group 
on CLIENT01.

**What I learned:** This is a great interview question answer because it 
shows you understand the distinction between authentication (who are you) 
and authorization (what are you allowed to do). It also shows that the 
local groups on a domain-joined machine still matter — domain membership 
doesn't replace local security model, it extends it.

## PowerShell Beats GUI for Repeatable Operations

I started by creating users in the ADUC GUI but quickly switched to 
PowerShell for the bulk creation. Reasons:

- Creating 8 users via GUI = 80 clicks
- Creating 8 users via PowerShell = one script execution
- Script can be re-run if the lab gets recreated
- Script documents itself — anyone reading it understands what was done

**What I learned:** GUI is for daily operations (one-off tasks like 
resetting Sarah's password). PowerShell is for setup, bulk operations, 
and reporting. Real admins use both — knowing which tool fits the moment 
is part of the skill.

## DSRM Password Should Be Different from Domain Admin

When promoting the domain controller, you're prompted for a Directory 
Services Restore Mode (DSRM) password. The temptation is to use the same 
password as the domain admin account for simplicity.

**Don't do this.** The DSRM password exists specifically because if the 
domain admin password is compromised, you need a separate recovery 
mechanism. Keeping them different is a security principle, not a 
convenience choice.

**What I learned:** Security best practices often look like "extra hassle" 
until you understand the threat model they're protecting against.

## Inheritance Visualization Is Better in PowerShell Than GUI

The GUI permission editor shows you the access list but obscures whether 
each entry is inherited from a parent. The `Get-Acl` PowerShell cmdlet 
exposes the `IsInherited` property cleanly. When I was auditing the 
permission leak, I literally couldn't see the problem in the GUI — but 
PowerShell showed it immediately.

**What I learned:** When the GUI hides important data, drop to PowerShell 
or the command line. Modern enterprise tools all have CLI/scripting 
interfaces for exactly this reason.

## Auto-Shutdown Is the Cost Safety Net I Needed

Azure for Students has a $100 credit cap that auto-disables the 
subscription when exhausted. But within that cap, careless VM management 
can burn cash fast. A B2ms running 24/7 is roughly $66/month — leave it 
on for two weeks and you've burned $33 doing nothing.

**The safety net:** Auto-shutdown configured for 11 PM Eastern on every VM.

**What I learned:** When forming the habit of cloud resource management, 
build in automated safety nets early. Hope is not a strategy when it 
comes to billing.

## Documentation Is the Skill, Not the Output

I built this lab to learn IT support. I documented it to remember what I 
learned. But the documentation process itself reinforced the learning — 
explaining a permission model in writing required me to actually 
understand it, not just click through the GUI.

**What I learned:** If you can't explain what you built and why, you 
haven't really learned it. Documentation isn't a separate task from 
building — it's the second half of building.

## Azure vCPU Quota Forced a Better Architecture

When I tried to add a third VM to the lab (TICKET01 for the helpdesk), 
Azure rejected the deployment: "Insufficient quota — family limit. 2 vCPUs 
are needed but only 0 vCPUs of 4 remain for the Standard BS Family." DC01 
(2 vCPU) plus CLIENT01 (2 vCPU) had consumed my entire B-family allowance 
in East US.

**The pivot:** Instead of deallocating CLIENT01, I deployed TICKET01 in 
East US 2, which has its own separate quota pool. This required setting 
up cross-region VNet peering to connect the two networks — adding genuine 
multi-region networking to the lab.

**What I learned:** Constraints often force better architectures than the 
ones I'd have built without them. Cross-region deployment is how real 
enterprises distribute workloads, and the resulting lab is more impressive 
than the single-region version would have been. The "workaround" became 
the feature.

## The `.local` Domain Conflicts with Linux mDNS

After configuring TICKET01 (Ubuntu) to use DC01 as its DNS server, 
`nslookup dc01.corp.local` returned SERVFAIL — but `dig @10.0.1.4 
dc01.corp.local` (querying DC01 directly) worked perfectly. The query 
was being intercepted somewhere before it reached the DC.

**The cause:** RFC 6762 reserves the `.local` TLD for Multicast DNS 
(Apple Bonjour, Avahi, printer discovery). Modern Linux distributions 
honor this — systemd-resolved hijacks `.local` queries and tries mDNS 
on the local subnet instead of forwarding to upstream DNS. Active 
Directory has used `.local` since the 1990s, predating this RFC. 
Documented conflict.

**The fix:** A systemd-resolved drop-in config at 
`/etc/systemd/resolved.conf.d/no-mdns.conf` disables mDNS/LLMNR and 
explicitly routes corp.local queries to upstream DNS. See 
`scripts/ticket01-no-mdns.conf` for the reusable file.

**What I learned:** Modern Linux DNS is more complex than 
`/etc/resolv.conf`. Production AD deployments today should use a 
real-internet TLD (like corp.example.com) to avoid this issue entirely. 
This is also a portable fix — any future Linux VM in the lab uses the 
same config file.

## Windows Server 2025 Enforces LDAP Signing by Default

When I tested LDAP bind from TICKET01 to DC01 (plain LDAP, port 389), 
it failed with "Strong(er) authentication required (8) — DSID-0C09035C." 
The credentials were correct — DC01 was refusing the bind because it 
wasn't encrypted or signed.

**The cause:** Microsoft hardened Windows Server defaults in 2022+ to 
reject unsigned, unencrypted LDAP binds. This is enforced through Group 
Policy and overrides the registry setting that controls it.

**The fix path:** I first modified the Default Domain Controllers Policy 
to set "Domain controller: LDAP server signing requirements" to None — 
this got the bind working but wasn't the right long-term answer. The 
correct fix was deploying AD Certificate Services as an Enterprise Root 
CA, which auto-enrolled a Domain Controller certificate and activated 
LDAPS on port 636. Authentication moved to encrypted LDAPS, sidestepping 
the signing requirement entirely.

**What I learned:** When a security control blocks you, the question to 
ask is "what is this control protecting against, and what's the right 
way to satisfy it?" rather than "how do I disable it?" In this case the 
right answer was deploying PKI, not relaxing GPO. The lab now has a 
working internal CA, which unlocks future projects (LDAPS, encrypted 
SMB signing, code signing, etc.).

## Knowing When to Stop Fighting a Tool

After all the network, DNS, firewall, and LDAPS pieces verified working 
at the command line, the osTicket auth-ldap plugin v0.6.2 still had 
intermittent failures. The Apache error log showed:

```
TypeError: ldap_close(): Argument #1 ($ldap) must be of type 
LDAP\Connection, false given
```

This is a documented PHP 8.x compatibility issue inside the plugin's 
bundled Net_LDAP2 PEAR library — the old code passes `false` to 
`ldap_close()` when a connection failed, and PHP 8 strictly rejects 
that. The plugin partially works (it pulls user attributes from AD 
successfully) but the full authentication flow is inconsistent.

**The decision:** Rather than patching deprecated PEAR code inside a 
`.phar` archive, I documented this as a known limitation and identified 
the production path forward: migrate to OAuth2 authentication via 
Microsoft Entra ID using osTicket's actively maintained OAuth2 plugin.

**What I learned:** Knowing when to stop trying to fix a tool and pivot 
to a better tool is itself a skill. The hours that would go into 
patching a deprecated library are better spent learning a modern 
alternative — and in interviews, "I hit an upstream bug, documented it 
honestly, and identified the production path forward" is a stronger 
answer than "I monkey-patched a PEAR library to make it work."

## What I'd Do Differently Next Time

1. **Audit permissions immediately after each change**, not in a 
   "verification pass" at the end. The audit script would have caught 
   the inheritance issue immediately if I'd run it after each share.

2. **Build a member server early** instead of putting shares on the DC. 
   Production environments never put file shares on the DC; doing it 
   anyway in the lab created a habit I'd have to unlearn.

3. **Set up Azure cost alerts at $25 and $50** as additional safety nets, 
   even though the student subscription has a hard cap. Belt and 
   suspenders.

4. **Take screenshots while building**, not afterward. Several "proof" 
   moments would have been easier to capture in real-time than trying 
   to reconstruct them.

5. **Use Mermaid diagrams in documentation from the start** — much faster 
   than going back and adding visual aids later.

## What's Next

This lab is the foundation, not the finish line. Future projects 
building on this:

- **OAuth2 / Entra ID authentication for osTicket** — replaces the 
  partially-working LDAP plugin with Microsoft's modern auth path
- **Member server (FILE01)** for proper file share separation away 
  from the domain controller
- **Second domain controller (DC02)** for replication and FSMO redundancy
- **Microsoft Sentinel integration** for log collection and SIEM 
  experience
- **Sysmon deployment** for endpoint visibility on CLIENT01
- **AD CS publishing** of the LDAPS certificate chain to Linux trust 
  stores (replacing `TLS_REQCERT never` with proper cert validation)
- **Migrate entire setup to Proxmox** when home lab hardware is built
