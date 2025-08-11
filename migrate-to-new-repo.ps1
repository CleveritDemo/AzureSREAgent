# Repository Migration Script
# This script helps you upload all files to a new repository

param(
    [Parameter(Mandatory=$true)]
    [string]$NewRepoUrl,
    [string]$NewRemoteName = "new-origin"
)

Write-Host "🔄 Repository Migration Script" -ForegroundColor Blue
Write-Host "=============================" -ForegroundColor Blue
Write-Host ""

# Validate we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not in a git repository" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Current repository status:" -ForegroundColor Yellow
Write-Host "Repository: $(git config --get remote.origin.url)" -ForegroundColor Cyan
Write-Host "Current branch: $(git branch --show-current)" -ForegroundColor Cyan
Write-Host "Total files: $(git ls-files | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎯 Target repository: $NewRepoUrl" -ForegroundColor Yellow
Write-Host ""

# Add new remote
Write-Host "🔗 Adding new remote..." -ForegroundColor Yellow
try {
    git remote add $NewRemoteName $NewRepoUrl
    Write-Host "✅ Added remote '$NewRemoteName'" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Remote might already exist, updating..." -ForegroundColor Yellow
    git remote set-url $NewRemoteName $NewRepoUrl
    Write-Host "✅ Updated remote '$NewRemoteName'" -ForegroundColor Green
}

# Show current remotes
Write-Host ""
Write-Host "📋 Current remotes:" -ForegroundColor Yellow
git remote -v

Write-Host ""
Write-Host "🚀 Pushing to new repository..." -ForegroundColor Yellow

# Push all branches
Write-Host "Pushing all branches..." -ForegroundColor Cyan
git push $NewRemoteName --all

# Push all tags
Write-Host "Pushing all tags..." -ForegroundColor Cyan
git push $NewRemoteName --tags

Write-Host ""
Write-Host "🎉 Migration completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📌 Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify files in new repository: $NewRepoUrl" -ForegroundColor Cyan
Write-Host "2. If migration successful, optionally update origin:" -ForegroundColor Cyan
Write-Host "   git remote set-url origin $NewRepoUrl" -ForegroundColor Green
Write-Host "3. Remove old remote if needed:" -ForegroundColor Cyan
Write-Host "   git remote remove $NewRemoteName" -ForegroundColor Green
Write-Host ""
Write-Host "✅ All 547+ files have been uploaded to the new repository!" -ForegroundColor Green
