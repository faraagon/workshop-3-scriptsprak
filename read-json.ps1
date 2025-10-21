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


#Create a list of users whose lastLogon date is older 
#than 30 days compared to the current date
$inactiveUsers = $data.users | Where-Object {
    #Convert lastLogon to datetime and compare to todays date minus 30 days
    ([datetime]$_.lastLogon) -lt (Get-Date).AddDays(-30)
}
#Loop through each inactive user and calculate how many days since last login
foreach ($user in $inactiveUsers) {
    $daysInactive = ((Get-Date) - [datetime]$user.lastLogon).Days
    Write-Host "$($user.displayName) $daysInactive dagar inaktiv"
}


#Print the number of inactive users
Write-Host ""
Write-Host "Totalt inaktiva användare: $($inactiveUsers.Count)"


#Empty counter to count users per department
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


#Export inactive user to CSV
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


#Section for password age per user starts
Write-Host "`nLösenordsålder per användare:"
Write-Host "============================"
#Loop through each user and calculate how many days ago the password was changed
foreach ($user in $data.users) {
    # Convert passwordLastSet to datetime and calculate the number of days, print it
    $pwdAge = ((Get-Date) - [datetime]$user.passwordLastSet).Days
    Write-Host "$($user.displayName): $pwdAge dagar gammalt lösenord"
}



#Oldest check-in section starts
Write-Host "`nTopp 10 datorer med längst tid sen senaste användning::"
Write-Host "============================"


$data.computers |
#Filter out posts without logon value
Where-Object { $_.lastLogon -ne $null -and $_.lastLogon -ne "" } |

#Sort after the oldest logon first
Sort-Object -Property lastLogon |

#Select the 10 oldest
Select-Object -First 10 |

#Calculate the time since last logon and print
ForEach-Object {
    $lastLogon = [datetime]$_.lastLogon
    $daysSinceLogon = ((Get-Date) - $lastLogon).Days
    Write-Host "$($_.name): $daysSinceLogon dagar sen senaste användning"
}
