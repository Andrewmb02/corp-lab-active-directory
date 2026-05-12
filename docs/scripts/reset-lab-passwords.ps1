<#
.SYNOPSIS
    Resets all lab user passwords to a known value for testing purposes.

.DESCRIPTION
    Lab convenience script that resets the password for all 9 lab users
    to the same known value, with "must change at next logon" disabled.
    This allows quick testing of different user contexts without managing
    individual passwords.

    NOT FOR PRODUCTION USE. In a real environment:
    - Passwords would be randomly generated per user
    - "Must change at logon" would always be enabled
    - Resets would be audited and logged

.NOTES
    Run on the domain controller as a Domain Admin.
#>

# Common password for all lab users
$NewPassword = ConvertTo-SecureString "Welcome2026!" -AsPlainText -Force

# All lab users to reset
$Users = @(
    "smitchell", "jchen", "erodriguez", "mthompson",
    "jpark", "dwilliams", "afoster", "rpatel", "landerson"
)

foreach ($u in $Users) {
    try {
        Set-ADAccountPassword -Identity $u -NewPassword $NewPassword -Reset
        Set-ADUser -Identity $u -ChangePasswordAtLogon $false
        Write-Host "Reset password for $u" -ForegroundColor Green
    } catch {
        Write-Host "Failed to reset $u : $_" -ForegroundColor Red
    }
}

Write-Host "`nAll lab users now have password: Welcome2026!" -ForegroundColor Yellow
Write-Host "Login format: CORP\<username> (e.g., CORP\smitchell)" -ForegroundColor Yellow
