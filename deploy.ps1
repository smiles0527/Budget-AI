<#
.SYNOPSIS
    Deploy the SnapBudget website to Vercel.

.DESCRIPTION
    Quick deploy script for the web/ Next.js app.
    - `.\deploy.ps1`          → preview deployment
    - `.\deploy.ps1 -Prod`    → production deployment

.EXAMPLE
    .\deploy.ps1
    .\deploy.ps1 -Prod
#>

param(
    [switch]$Prod
)

$ErrorActionPreference = "Stop"
$webDir = Join-Path $PSScriptRoot "web"

Write-Host ""
Write-Host "=== SnapBudget Deploy ===" -ForegroundColor Cyan

# Verify web directory exists
if (-not (Test-Path $webDir)) {
    Write-Host "ERROR: web/ directory not found at $webDir" -ForegroundColor Red
    exit 1
}

# Verify Vercel CLI is installed
if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Vercel CLI..." -ForegroundColor Yellow
    npm install -g vercel
}

# Move into web directory
Push-Location $webDir

try {
    # Install deps if node_modules is missing
    if (-not (Test-Path "node_modules")) {
        Write-Host "[1/3] Installing dependencies..." -ForegroundColor Yellow
        npm install
    } else {
        Write-Host "[1/3] Dependencies OK" -ForegroundColor Green
    }

    # Build
    Write-Host "[2/3] Building..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed." -ForegroundColor Red
        exit 1
    }
    Write-Host "[2/3] Build OK" -ForegroundColor Green

    # Deploy
    if ($Prod) {
        Write-Host "[3/3] Deploying to PRODUCTION..." -ForegroundColor Magenta
        vercel --prod
    } else {
        Write-Host "[3/3] Deploying preview..." -ForegroundColor Yellow
        vercel
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Deploy complete!" -ForegroundColor Green
    } else {
        Write-Host "Deploy returned non-zero exit code." -ForegroundColor Red
    }
} finally {
    Pop-Location
}
