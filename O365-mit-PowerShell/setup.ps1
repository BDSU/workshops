# ===== RESET FUNCTION =====
function Reset-Setup($i) {
    Write-Host -ForegroundColor Yellow "Resetting setup $i"
    Remove-DistributionGroup -Identity "trainees.$i@bdsu.it" -Confirm:$false
    Remove-DistributionGroup -Identity "mitglieder.$i@bdsu.it" -Confirm:$false
    New-DistributionGroup -Name "Trainees $i" -Type "Distribution" -PrimarySmtpAddress "trainees.$i@bdsu.it" | Out-Null
    New-DistributionGroup -Name "Mitglieder $i" -Type "Distribution" -PrimarySmtpAddress "mitglieder.$i@bdsu.it" | Out-Null
    Add-DistributionGroupMember -Identity "trainees.$i@bdsu.it" -Member $users_csv[$i].UserPrincipalName
}

# ===== CONNECT TO AZUREAD AND EXCHANGE =====
if (!$credential) {
    $credential = Get-Credential
}

Connect-AzureAD -Credential $credential

$sessions = Get-PSSession
if (!($sessions.ComputerName -contains "outlook.office365.com")) {

    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection
    if (!$? -or !$session) {
        error-exit "Konnte Exchange-Session nicht erstellen"
    }

    Import-PSSession $session
    if (!$?) {
        error-exit "Konnte Exchange-Session nicht importieren"
    }
}

# ===== GET USERS =====
$users_csv = Import-Csv -Path ".\demo_users.csv"

# ===== TRIGGER RESET PER SETUP SLOT =====
1..15 | ForEach-Object {
    Reset-Setup $_
}
