$data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json

Write-Host "==============================="
Write-Host " ACTIVE DIRECTORY - MÅNADSRAPPORT"
Write-Host "==============================="
Write-Host "Domännamn: $($data.domain)"
Write-Host "Exportdatum: $($data.exportDate)"