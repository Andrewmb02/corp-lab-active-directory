<#
.SYNOPSIS
    Bulk creation of lab user accounts in Active Directory.

.DESCRIPTION
    Creates 8 user accounts across 4 departments with proper metadata
    (title, department, UPN). Used during the initial setup of the
    corp.local lab environment.

    All users are created in the Employees OU. Default password is
    intentionally simple for lab purposes — in production this would
    use a generated random password with "must change at logon" enforced.

.NOTES
    Run on the domain controller (DC01) as a Domain Admin.
    Requires the ActiveDirectory PowerShell module.
#>

# Default password for all lab users
$Password = ConvertTo-SecureString "LabUser2026!" -AsPlainText -Force

# User definitions
$Users = @(
    @{First="Sarah";    Last="Mitchell";  Title="Sales Manager";    Dept="Sales"},
    @{First="James";    Last="Chen";      Title="Sales Rep";        Dept="Sales"},
    @{First="Emily";    Last="Rodriguez"; Title="Engineer";         Dept="Engineering"},
    @{First="Michael";  Last="Thompson";  Title="Engineer";         Dept="Engineering"},
    @{First="Jessica";  Last="Park";      Title="HR Manager";       Dept="HR"},
    @{First="David";    Last="Williams";  Title="HR Specialist";    Dept="HR"},
    @{First="Amanda";   Last="Foster";    Title="IT Support";       Dept="IT"},
    @{First="Ryan";     Last="Patel";     Title="IT Admin";         Dept="IT"}
)

foreach ($u in $Users) {
    # Build username from first initial + last name
    $username = ($u.First.Substring(0,1) + $u.Last).ToLower()
    $fullname = "$($u.First) $($u.Last)"
    
    New-ADUser `
        -Name $fullname `
        -GivenName $u.First `
        -Surname $u.Last `
        -SamAccountName $username `
        -UserPrincipalName "$username@corp.local" `
        -DisplayName $fullname `
        -Title $u.Title `
        -Department $u.Dept `
        -AccountPassword $Password `
        -Enabled $true `
        -Path "OU=Employees,DC=corp,DC=local" `
        -ChangePasswordAtLogon $false
    
    Write-Host "Created user: $username ($fullname) - $($u.Title)" -ForegroundColor Green
}

Write-Host "`nAll users created. Default password: LabUser2026!" -ForegroundColor Yellow
Write-Host "Verify with: Get-ADUser -Filter * -SearchBase 'OU=Employees,DC=corp,DC=local'" -ForegroundColor Yellow
