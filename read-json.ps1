#Read the JSON-file
$data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json

#Print out a header with domain and export date
Write-Host "============================"
Write-Host " ACTIVE DIRECTORY - MÅNADSRAPPORT"
Write-Host "============================"
Write-Host "Domännamn: $($data.domain)"
Write-Host "Exportdatum: $($data.export_date)`n"


#Find users that are inactive, 30 days+
Write-Host "Inaktiva användare (senaste 30 dagarna):"
Write-Host "============================"


#Create variable for inactive users
$inactiveUsers = $data.users | Where-Object {
    #Convert lastLogon to datetime and compare to todays date minus 30 days
    ([datetime]$_.lastLogon) -lt (Get-Date).AddDays(-30)
}

#Loop through the results and print out each inactive user
foreach ($user in $inactiveUsers) {
    $daysInactive = ((Get-Date) - [datetime]$user.lastLogon).Days
    Write-Host "$($user.displayName) $daysInactive dagar inaktiv"
}


#Print the number of inactive users
Write-Host ""
Write-Host "Totalt inaktiva användare: $($inactiveUsers.Count)"


#Empty counter for workers per department
$deptCounts = @{} 

#Loop through departments, if it doesn't exist add it. If it exist, +1
foreach ($user in $data.users) {
    $dept = $user.department

    if (-not $deptCounts.ContainsKey($dept)) {
        $deptCounts[$dept] = 0
    }
    $deptCounts[$dept]++
}

Write-Host ""
#Loop through list and print out result
Write-Host "Användare per avdelning:"
Write-Host "============================"
foreach ($dept in $deptCounts.Keys) {
    Write-Host "$dept : $($deptCounts[$dept]) användare"
}


# Exportera inaktiva användare till CSV
$inactiveUsers | Select-Object samAccountName, displayName, lastLogon, department, title |
Export-Csv -Path "inactive_users.csv" -NoTypeInformation

Write-Host ""
#Computers per site section
Write-Host "Datorer per site:"
Write-Host "============================"


$computersBySite = $data.computers | Group-Object -Property site

foreach ($group in $computersBySite) {
    Write-Host "$($group.Name): $($group.Count) datorer"
}

Write-Host ""

