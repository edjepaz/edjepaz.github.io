# Bootstrap Script - Redirect to Latest
# This fetches and executes the latest version from the main repo

$latestUrl = "https://raw.githubusercontent.com/edjepaz/bootstrap/main/bootstrap.ps1"
Invoke-Expression (Invoke-RestMethod $latestUrl)
