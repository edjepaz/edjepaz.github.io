#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bootstrap script to download and setup private scripts repository
.DESCRIPTION
    This script uses Git with SSH or HTTPS authentication to clone your private scripts repo
    Usage: irm raw.githubusercontent.com/edjepaz/bootstrap/main/bootstrap.ps1 | iex
    
    You can also pass parameters:
    irm raw.githubusercontent.com/edjepaz/bootstrap/main/bootstrap.ps1 | iex -ScriptsRepo "username/repo" -TargetPath "C:\MyScripts"
#>

param(
    [string]$ScriptsRepo = "",
    [string]$TargetPath = "$HOME\MyScripts",
    [string]$Branch = "master"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Bootstrap Script Installer" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Prompt for repository if not provided
if ([string]::IsNullOrWhiteSpace($ScriptsRepo)) {
    Write-Host "Enter your GitHub repository (format: username/repo-name)" -ForegroundColor Yellow
    Write-Host "Example: edjepaz/scripts" -ForegroundColor Gray
    $ScriptsRepo = Read-Host "Repository"
    
    if ([string]::IsNullOrWhiteSpace($ScriptsRepo)) {
        Write-Host "✗ Repository is required" -ForegroundColor Red
        exit 1
    }
    
    # Validate format
    if ($ScriptsRepo -notmatch '^[\w-]+/[\w-]+$') {
        Write-Host "✗ Invalid repository format. Use: username/repo-name" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Repository: $ScriptsRepo" -ForegroundColor Cyan
Write-Host "Target path: $TargetPath" -ForegroundColor Cyan
Write-Host "Branch: $Branch`n" -ForegroundColor Cyan

# Check if Git is installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitInstalled) {
    Write-Host "⚠ Git not found" -ForegroundColor Yellow
    Write-Host "Attempting to install Git...`n" -ForegroundColor Yellow
    
    # Try to install via winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Git for Windows..." -ForegroundColor Gray
        winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Git installed" -ForegroundColor Green
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
            
            if (-not $gitInstalled) {
                Write-Host "⚠ Git installed but not in PATH. Please restart your terminal." -ForegroundColor Yellow
                Write-Host "Then run this script again." -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "✗ Failed to install Git automatically" -ForegroundColor Red
            Write-Host "Please install Git manually from: https://git-scm.com/download/win" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "✗ winget not available" -ForegroundColor Red
        Write-Host "Please install Git manually from: https://git-scm.com/download/win" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✓ Git found" -ForegroundColor Green

# Determine clone URL
Write-Host "`n📦 Cloning private scripts repository..." -ForegroundColor Cyan
Write-Host "Repository: $ScriptsRepo" -ForegroundColor Gray

# Try HTTPS first (will prompt for credentials if needed)
$httpsUrl = "https://github.com/$ScriptsRepo.git"
$sshUrl = "git@github.com:$ScriptsRepo.git"

if (Test-Path $TargetPath) {
    Write-Host "⚠ Target path already exists: $TargetPath" -ForegroundColor Yellow
    $response = Read-Host "Do you want to update it? (y/n)"
    if ($response -eq 'y') {
        Push-Location $TargetPath
        Write-Host "Pulling latest changes..." -ForegroundColor Yellow
        git pull origin $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Repository updated" -ForegroundColor Green
        } else {
            Write-Host "⚠ Update failed, continuing..." -ForegroundColor Yellow
        }
        Pop-Location
    } else {
        Write-Host "Skipping clone" -ForegroundColor Yellow
    }
} else {
    Write-Host "Attempting to clone with HTTPS..." -ForegroundColor Gray
    Write-Host "(Git will prompt for authentication if needed)" -ForegroundColor Gray
    
    # Clone the repository
    git clone --branch $Branch $httpsUrl $TargetPath 2>&1 | Out-String | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Repository cloned to: $TargetPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to clone repository" -ForegroundColor Red
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Make sure you have access to the repository" -ForegroundColor Gray
        Write-Host "2. Git may have prompted for credentials - check above" -ForegroundColor Gray
        Write-Host "3. You can also try manually: git clone $httpsUrl $TargetPath" -ForegroundColor Gray
        exit 1
    }
}

# Check for install script in the cloned repo
$installScript = Join-Path $TargetPath "install.ps1"
if (Test-Path $installScript) {
    Write-Host "`n🔧 Found install.ps1 in repository" -ForegroundColor Cyan
    Write-Host "Location: $installScript" -ForegroundColor Gray
    Write-Host "`n⚠ WARNING: This script will be executed on your system" -ForegroundColor Yellow
    $response = Read-Host "Do you want to run it? (y/n)"
    
    if ($response -eq 'y') {
        Write-Host "`nRunning install script..." -ForegroundColor Cyan
        & $installScript
        Write-Host "`n✓ Install script completed" -ForegroundColor Green
    } else {
        Write-Host "`nSkipped running install.ps1" -ForegroundColor Yellow
        Write-Host "You can run it manually later: & '$installScript'" -ForegroundColor Gray
    }
} else {
    Write-Host "`n✓ Setup complete! Scripts are in: $TargetPath" -ForegroundColor Green
    Write-Host "No install.ps1 found in repository - manual setup may be needed" -ForegroundColor Yellow
}

Write-Host "`n✨ Bootstrap complete!" -ForegroundColor Green
Write-Host "Scripts location: $TargetPath" -ForegroundColor Cyan
