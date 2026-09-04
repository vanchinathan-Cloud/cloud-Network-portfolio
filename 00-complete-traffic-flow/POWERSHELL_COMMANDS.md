# PowerShell Commands - Module 00 Deployment Reference

## Quick Copy-Paste Commands

### ⚡ Option A: Quick Deploy (5 minutes)

```powershell
# 1. Navigate to repo
cd C:\path\to\enterprise-aws-cloud-network-infrastructure

# 2. Run quick deploy
.\quick-deploy-module-00.ps1

# 3. Commit and push
git add 00-aws-traffic-flow/
git commit -m "Add Module 00: Complete AWS Traffic Flow - Quick Start"
git push origin main
```

---

### ⚙️ Option B: Full Deploy (10 minutes)

```powershell
# 1. Navigate to repo
cd C:\path\to\enterprise-aws-cloud-network-infrastructure

# 2. Run full deploy (no auto-push)
.\deploy-module-00.ps1

# 3. Review changes
git status
git diff --cached

# 4. Commit and push
git commit -m "Add Module 00: Complete AWS Traffic Flow"
git push origin main
```

**OR with auto-push:**
```powershell
# One command deploy with automatic push
.\deploy-module-00.ps1 -AutoPush
```

---

### 🔧 Option C: Manual Commands

```powershell
# 1. Create directory structure
cd C:\path\to\enterprise-aws-cloud-network-infrastructure
mkdir 00-aws-traffic-flow
cd 00-aws-traffic-flow

# 2. Create files (open in editor or use New-Item)
# Copy content from README_REFACTORED.md to README.md
# Copy architecture-diagram.svg
# Create QUICK_REFERENCE.md and TROUBLESHOOTING.md

# 3. Go back to root
cd ..

# 4. Add and commit
git add 00-aws-traffic-flow/
git commit -m "Add Module 00: Complete AWS Traffic Flow"
git push origin main
```

---

## Common Git Commands

### View Status
```powershell
# See all changes
git status

# See detailed changes
git diff --cached

# See file tree
tree 00-aws-traffic-flow/ /F
```

### Staging
```powershell
# Stage everything
git add .

# Stage specific directory
git add 00-aws-traffic-flow/

# Stage specific file
git add 00-aws-traffic-flow/README.md

# Unstage if needed
git reset 00-aws-traffic-flow/README.md
```

### Committing
```powershell
# Simple commit
git commit -m "Add Module 00: Complete AWS Traffic Flow"

# Detailed commit
git commit -m "Add Module 00: Complete AWS Traffic Flow" -m "This includes:
- README with 11-layer traffic flow
- Architecture diagram
- Troubleshooting guide
- Quick reference"

# Amend last commit (before push)
git commit --amend -m "New message"
```

### Pushing
```powershell
# Push to main branch
git push origin main

# Push to other branch
git push origin development

# Push with dry-run (see what would happen)
git push --dry-run origin main
```

---

## Verification Commands

### Check Files Were Created
```powershell
# List module directory
ls 00-aws-traffic-flow/

# Show file structure
tree 00-aws-traffic-flow/

# Count files
(ls 00-aws-traffic-flow/ -Recurse).Count

# Show total size
(ls 00-aws-traffic-flow/ -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB
```

### Check Git Log
```powershell
# See recent commits
git log --oneline -5

# See commit tree
git log --all --graph --oneline --decorate

# See commits affecting module
git log --oneline -- 00-aws-traffic-flow/
```

### Validate Files
```powershell
# Check README exists and has content
(Get-Content 00-aws-traffic-flow/README.md | Measure-Object -Line).Lines

# Check SVG is valid
[xml]$svg = Get-Content 00-aws-traffic-flow/architecture-diagram.svg
"SVG has $($svg.svg.ChildNodes.Count) elements"

# Check all required files exist
$required = @('README.md', 'QUICK_REFERENCE.md', 'TROUBLESHOOTING.md', 'architecture-diagram.svg')
$required | ForEach-Object { 
    if (Test-Path "00-aws-traffic-flow/$_") { "✓ $_" } else { "✗ $_ MISSING" }
}
```

---

## Troubleshooting Commands

### If Execution Policy Blocked
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run script
.\deploy-module-00.ps1
```

### If Git Config Missing
```powershell
# Set username
git config --global user.name "Your Name"

# Set email
git config --global user.email "your.email@example.com"

# Verify
git config --global --list
```

### If Remote URL Wrong
```powershell
# Check current remote
git remote -v

# Update remote
git remote set-url origin https://github.com/YOUR-USERNAME/enterprise-aws-cloud-network-infrastructure.git

# Or use SSH
git remote set-url origin git@github.com:YOUR-USERNAME/enterprise-aws-cloud-network-infrastructure.git
```

### If Authentication Fails
```powershell
# Set credential helper (Windows)
git config --global credential.helper manager-core

# Force re-authentication
git credential approve  # Press Ctrl+D after entering credentials

# Then retry push
git push origin main
```

### Undo Recent Changes
```powershell
# Undo uncommitted changes
git checkout -- 00-aws-traffic-flow/

# Undo staged changes
git reset HEAD 00-aws-traffic-flow/

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo last push (if not yet pulled by others)
git push --force-with-lease origin main
```

---

## File Creation Commands

### Using PowerShell New-Item
```powershell
# Create directory
mkdir 00-aws-traffic-flow

# Create empty file
New-Item -Path "00-aws-traffic-flow/README.md" -ItemType File

# Create file with content
@"
# 0 — Complete AWS Traffic Flow

Module content here...
"@ | Set-Content 00-aws-traffic-flow/README.md
```

### Using Copy-Item
```powershell
# Copy file from current location
Copy-Item -Path "architecture-diagram.svg" -Destination "00-aws-traffic-flow/"

# Copy with verbose output
Copy-Item -Path "architecture-diagram.svg" -Destination "00-aws-traffic-flow/" -Verbose
```

### Using Get-Content and Set-Content
```powershell
# Read from template and write to new file
Get-Content "README_REFACTORED.md" | Set-Content "00-aws-traffic-flow/README.md"

# Append to existing file
Add-Content -Path "00-aws-traffic-flow/README.md" -Value "`n`nAdditional content..."
```

---

## Advanced Git Commands

### Create Feature Branch
```powershell
# Create new branch
git checkout -b feature/module-00

# Push new branch
git push -u origin feature/module-00

# Then create Pull Request on GitHub
```

### Squash Multiple Commits
```powershell
# Before pushing, combine commits
git rebase -i HEAD~3  # Combines last 3 commits

# Mark commits as 'squash' in editor, save
# Then force push (only if not shared yet!)
git push --force-with-lease origin main
```

### Sign Commits (GPG)
```powershell
# Configure GPG signing
git config --global user.signingkey YOUR-GPG-KEY

# Sign commit
git commit -S -m "Add Module 00"

# Enable signing for all commits
git config --global commit.gpgSign true
```

---

## Performance Commands

### Check Repository Size
```powershell
# Size of .git directory
(Get-Item .git -Force).Size / 1MB

# Size of module directory
(ls 00-aws-traffic-flow/ -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB

# Total repo size
(ls . -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
```

### Cleanup Repository
```powershell
# Remove untracked files
git clean -fd

# Optimize git database
git gc --aggressive

# Prune old objects
git prune
```

---

## Batch Operations

### Create All Module Files at Once
```powershell
$modulePath = "00-aws-traffic-flow"
mkdir $modulePath

# Create all files
@{
    "README.md" = "# 0 — Complete AWS Traffic Flow`n`n..."
    "QUICK_REFERENCE.md" = "# Quick Reference`n`n..."
    "TROUBLESHOOTING.md" = "# Troubleshooting`n`n..."
} | ForEach-Object {
    $_.GetEnumerator() | ForEach-Object {
        Set-Content -Path "$modulePath/$($_.Key)" -Value $_.Value
    }
}

# Copy SVG
Copy-Item "architecture-diagram.svg" "$modulePath/"

# Add all and commit
git add $modulePath/
git commit -m "Add Module 00: Complete AWS Traffic Flow"
git push origin main
```

### Validate All Commands
```powershell
# This script verifies everything is ready to deploy
$modulePath = "00-aws-traffic-flow"
$requiredFiles = @('README.md', 'QUICK_REFERENCE.md', 'TROUBLESHOOTING.md', 'architecture-diagram.svg')

Write-Host "=== Module 00 Validation ===" -ForegroundColor Cyan
Write-Host ""

# Check directory
if (Test-Path $modulePath) {
    Write-Host "✓ Module directory exists" -ForegroundColor Green
} else {
    Write-Host "✗ Module directory missing" -ForegroundColor Red
}

# Check files
Write-Host "Checking files:"
$requiredFiles | ForEach-Object {
    $path = "$modulePath/$_"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length / 1KB
        Write-Host "  ✓ $_ ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $_ (MISSING)" -ForegroundColor Red
    }
}

# Check git
Write-Host ""
Write-Host "Git status:"
git status --short | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Ready to push? Run: git push origin main" -ForegroundColor Yellow
```

---

## One-Liner Deployment

If you want absolute quickest:

```powershell
# Single line (quick deploy + push)
mkdir 00-aws-traffic-flow; cd 00-aws-traffic-flow; New-Item README.md -Value "# 0 — Complete AWS Traffic Flow`n`nSee parent directory for full content."; cd ..; git add 00-aws-traffic-flow/; git commit -m "Add Module 00"; git push
```

---

## Recommended Workflow

```powershell
# 1. Setup
cd C:\your\repo
git checkout main
git pull origin main

# 2. Deploy
.\deploy-module-00.ps1

# 3. Review
git status
git diff --cached
ls 00-aws-traffic-flow/ -Recurse

# 4. Commit
git commit -m "Add Module 00: Complete AWS Traffic Flow"

# 5. Push
git push origin main

# 6. Verify
start "https://github.com/YOUR-USERNAME/enterprise-aws-cloud-network-infrastructure/tree/main/00-aws-traffic-flow"
```

---

## Cheat Sheet Quick Links

| Command | Purpose |
|---------|---------|
| `git status` | See what's changed |
| `git add 00-aws-traffic-flow/` | Stage module |
| `git commit -m "message"` | Create commit |
| `git push origin main` | Push to GitHub |
| `git log --oneline -5` | See recent commits |
| `git diff --cached` | See staged changes |
| `git reset --soft HEAD~1` | Undo last commit |
| `.\deploy-module-00.ps1` | Run full deployment |
| `.\quick-deploy-module-00.ps1` | Run quick deployment |
| `tree 00-aws-traffic-flow/` | View directory tree |
| `git remote -v` | Check remote URL |

---

**Last Updated**: September 2026  
**Tested On**: PowerShell 7.4, Git 2.42
