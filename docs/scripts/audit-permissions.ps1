<#
.SYNOPSIS
    Audits NTFS permissions across the lab file share structure.

.DESCRIPTION
    Reports non-default permission entries on each share folder, with
    inheritance status. Used to detect permission sprawl — particularly
    where permissions have been incorrectly applied to a parent folder
    and are inheriting down to children.

    Filters out default SYSTEM, Administrators, and Creator Owner entries
    since those are expected on all folders.

.NOTES
    Run on the file server (in this lab, DC01).
    Compare output to the expected permission matrix in
    docs/04-file-services.md.
#>

$Folders = @(
    "C:\Shares",
    "C:\Shares\Sales",
    "C:\Shares\Engineering",
    "C:\Shares\HR",
    "C:\Shares\Public"
)

foreach ($folder in $Folders) {
    Write-Host "`n=== $folder ===" -ForegroundColor Yellow
    
    if (-not (Test-Path $folder)) {
        Write-Host "  (folder does not exist)" -ForegroundColor Red
        continue
    }
    
    $acl = Get-Acl $folder
    
    $custom = $acl.Access | Where-Object {
        $_.IdentityReference -notlike "NT AUTHORITY\SYSTEM" -and
        $_.IdentityReference -notlike "BUILTIN\Administrators" -and
        $_.IdentityReference -notlike "CREATOR OWNER"
    }
    
    if ($custom.Count -eq 0) {
        Write-Host "  (no custom permission entries)" -ForegroundColor Gray
    } else {
        $custom | Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited |
            Format-Table -AutoSize
    }
}

Write-Host "`nExpected permissions per folder:" -ForegroundColor Cyan
Write-Host "  C:\Shares             - (no custom entries)" -ForegroundColor Cyan
Write-Host "  C:\Shares\Sales       - CORP\Sales-Team (Modify, IsInherited=False)" -ForegroundColor Cyan
Write-Host "  C:\Shares\Engineering - CORP\Engineering-Team (Modify, IsInherited=False)" -ForegroundColor Cyan
Write-Host "  C:\Shares\HR          - CORP\HR-Team (Modify, IsInherited=False)" -ForegroundColor Cyan
Write-Host "  C:\Shares\Public      - CORP\IT-Admins (Modify) + CORP\All-Employees (ReadAndExecute)" -ForegroundColor Cyan
