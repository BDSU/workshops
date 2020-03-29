# ===== CONFIG DEMO SETUP =====
$DEMO = 1

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

# ===== PROMOTE OLD TRAINEES =====
$old_trainees = Get-DistributionGroupMember -Identity "trainees.$DEMO@bdsu.it"
$old_trainees | ForEach-Object {
    Write-Host "Trainee promoted:" $_.PrimarySmtpAddress
    Remove-DistributionGroupMember -Identity "trainees.$DEMO@bdsu.it" -Member $_.PrimarySmtpAddress -Confirm:$false
    Add-DistributionGroupMember -Identity "mitglieder.$DEMO@bdsu.it" -Member $_.PrimarySmtpAddress
}

# ===== INSERT NEW TRAINEES =====
$new_trainees = Import-Csv -Path ".\demo_users.csv" | Where-Object { $_.demo -eq $DEMO }
$new_trainees | ForEach-Object {
    Write-Host "New trainee:" $_.UserPrincipalName
    Add-DistributionGroupMember -Identity "trainees.$DEMO@bdsu.it" -Member $_.UserPrincipalName
}

# ===== CHECK RESULT =====
$check_trainees = Get-DistributionGroupMember -Identity "trainees.$DEMO@bdsu.it"
$check_mitglieder = Get-DistributionGroupMember -Identity "mitglieder.$DEMO@bdsu.it"

Write-Host -ForegroundColor green "Checking members: Trainees $DEMO"
$check_trainees | ForEach-Object {
    Write-Host "Trainee:" $_.PrimarySmtpAddress
}
Write-Host -ForegroundColor green "Checking members: Mitglieder $DEMO"
$check_mitglieder | ForEach-Object {
    Write-Host "Mitglied:" $_.PrimarySmtpAddress
}

# ===== ALTER MODERATORS =====
$moderators = "mikel@bdsu.it", "roman@bdsu.it"
"trainees.$DEMO@bdsu.it", "mitglieder.$DEMO@bdsu.it" | ForEach-Object {
    Set-DistributionGroup -Identity $_ -ModerationEnabled $true -ModeratedBy $moderators
}