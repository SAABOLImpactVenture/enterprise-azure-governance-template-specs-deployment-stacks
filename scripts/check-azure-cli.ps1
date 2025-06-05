# Simple diagnostic script to check Azure CLI capabilities

Write-Host "---------------------------------------------------" -ForegroundColor Yellow
Write-Host "AZURE CLI DIAGNOSTIC INFORMATION" -ForegroundColor Yellow
Write-Host "---------------------------------------------------" -ForegroundColor Yellow

# Check Azure CLI version
Write-Host "1. Azure CLI Version:" -ForegroundColor Cyan
az --version

# Check if account extension is installed
Write-Host "`n2. Installed Extensions:" -ForegroundColor Cyan
az extension list --output table

# Try to list available account commands
Write-Host "`n3. Available Account Commands:" -ForegroundColor Cyan
az account --help

# Check if the alias command exists
Write-Host "`n4. Account Alias Commands (if available):" -ForegroundColor Cyan
az account alias --help 2>&1

# Check if the subscription create command exists (both possible paths)
Write-Host "`n5. Testing Subscription Creation Commands:" -ForegroundColor Cyan
Write-Host "5.1. account subscription create:" -ForegroundColor Gray
az account subscription --help 2>&1

Write-Host "`n5.2. account alias create:" -ForegroundColor Gray
az account alias create --help 2>&1

Write-Host "`n5.3. billing subscription create:" -ForegroundColor Gray
az billing subscription --help 2>&1

# Check available billing accounts
Write-Host "`n6. Available Billing Accounts:" -ForegroundColor Cyan
az billing account list --output table 2>&1

Write-Host "`n---------------------------------------------------" -ForegroundColor Yellow
Write-Host "END OF DIAGNOSTIC INFORMATION" -ForegroundColor Yellow
Write-Host "---------------------------------------------------" -ForegroundColor Yellow
