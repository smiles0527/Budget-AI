param(
  [string]$MigrationDir = "db/migrations",
  [string]$ServiceName = "snapbudget-postgres"
)

$pgUser = $Env:POSTGRES_USER; if (-not $pgUser) { $pgUser = 'app' }
$pgDb = $Env:POSTGRES_DB; if (-not $pgDb) { $pgDb = 'appdb' }
$pgPassword = $Env:POSTGRES_PASSWORD; if (-not $pgPassword) { $pgPassword = 'password' }

Write-Host "Applying migrations to service '$ServiceName' as user '$pgUser' db '$pgDb'..."

docker exec $ServiceName sh -lc "mkdir -p /migrations" | Out-Null

Get-ChildItem -Path $MigrationDir -Filter *.sql | Sort-Object Name | ForEach-Object {
  $fileName = $_.Name
  $fullPath = $_.FullName
  Write-Host "- Copying $fileName"
  docker cp $fullPath "$ServiceName:/migrations/$fileName" | Out-Null
  Write-Host "- Running $fileName"
  docker exec -e PGPASSWORD=$pgPassword -i $ServiceName psql -h 127.0.0.1 -U $pgUser -d $pgDb -v ON_ERROR_STOP=1 -f "/migrations/$fileName" | Write-Host
}

Write-Host "Migrations complete."


