# 09 — Lessons Learned

## Honest Reflections from Building This Lab

This document captures the gotchas, mistakes, and insights from the build 
process. It's the file most worth reading for anyone trying to build a 
similar lab — and the one most worth referencing in interviews when asked 
"what was challenging?"

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

- **Member server (FILE01)** for proper file share separation
- **Second domain controller (DC02)** for replication and FSMO redundancy
- **Microsoft Sentinel integration** for log collection and detection
- **Sysmon deployment** for endpoint visibility
- **osTicket self-hosted** to add web stack experience
- **Migrate entire setup to Proxmox** when home lab hardware is built
