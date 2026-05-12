# 07 — End-to-End Access Control Testing

## Goal

Verify the role-based access control model works correctly by logging in 
as different domain users and confirming they have exactly the access 
expected — no more, no less.

## Test Methodology

Each test follows the same pattern:
1. Log into CLIENT01 as a specific domain user
2. Attempt to access each of the four file shares
3. Document expected vs actual result
4. Test write access where applicable

## Test Subject 1: Sarah Mitchell (smitchell)

**Group Memberships:** Domain Users, Sales-Team, All-Employees

| Resource | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Logon banner | Displays before desktop | Displayed | ✅ |
| \\DC01\Sales | Read/write access | Opened, can create files | ✅ |
| \\DC01\Engineering | Access denied | "Windows cannot access..." | ✅ |
| \\DC01\HR | Access denied | "You do not have permission" | ✅ |
| \\DC01\Public | Read-only access | Opened, cannot write | ✅ |

## Test Subject 2: Amanda Foster (afoster)

**Group Memberships:** Domain Users, IT-Admins, All-Employees

| Resource | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Logon banner | Displays before desktop | Displayed | ✅ |
| \\DC01\Sales | Access denied | Confirmed denied | ✅ |
| \\DC01\Engineering | Access denied | Confirmed denied | ✅ |
| \\DC01\HR | Access denied | Confirmed denied | ✅ |
| \\DC01\Public | Read/write access | Opened, can create files | ✅ |

Note: IT-Admins has Modify on Public (administrative content management), 
but no access to department shares — IT staff don't automatically get to 
see department-private data. This mirrors least-privilege design.

## Test Subject 3: Jessica Park (jpark)

**Group Memberships:** Domain Users, HR-Team, All-Employees

| Resource | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Logon banner | Displays before desktop | Displayed | ✅ |
| \\DC01\Sales | Access denied | Confirmed denied | ✅ |
| \\DC01\Engineering | Access denied | Confirmed denied | ✅ |
| \\DC01\HR | Read/write access | Opened, can create files | ✅ |
| \\DC01\Public | Read-only access | Opened, cannot write | ✅ |

## What This Validates

A complete authentication and authorization flow:

1. **Authentication** — domain credentials validated by DC
2. **Token issuance** — Kerberos ticket with group memberships
3. **Network access** — SMB session established to DC01
4. **Authorization** — NTFS permissions enforced based on token
5. **Differential access** — same shares, different users, different results

## Interview Demonstration

The most visually compelling tests are:

1. **Same user, two outcomes** — Sarah accesses Sales but is denied HR
2. **Different users, different access** — afoster vs jpark show role 
   separation
3. **Read-only enforcement** — any user accessing Public can read but 
   cannot create files

Screenshots of the "Access Denied" dialogs are the strongest visual proof 
that the security model is functional.

## Failure Modes Worth Knowing

If access tests fail unexpectedly, common causes include:

- **Stale token** — user logged in before being added to a group. Fix: 
  log out and back in for token refresh.
- **Replication delay** — in multi-DC environments, group changes may 
  take time to propagate. Lab has single DC so this doesn't apply.
- **Inherited permissions** — if a parent folder grants broader access, 
  it can override subfolder denies. Audit with PowerShell.
- **Share vs NTFS conflict** — most restrictive wins. If share is Read 
  but NTFS is Modify, user gets Read.
- **Cached credentials** — Windows may cache old auth context. Restart 
  the client to clear.
