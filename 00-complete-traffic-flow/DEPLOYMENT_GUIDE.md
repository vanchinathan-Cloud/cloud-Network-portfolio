# Module 00 Deployment Guide - PowerShell Commands

## Overview

This guide provides **three deployment options** for adding Module 00 to your GitHub repository:

1. **Option A: Quick Deploy** (5 minutes) - Minimal setup
2. **Option B: Full Deploy** (10 minutes) - Complete with all files
3. **Option C: Manual Step-by-Step** (15 minutes) - Full control

---

## Prerequisites

### Required
- ✅ Git installed and configured
- ✅ PowerShell 7+ (or PowerShell 5.1+ on Windows)
- ✅ Repository cloned locally
- ✅ SSH or HTTPS git credentials configured

### Optional
- AWS CLI installed (for validation commands)
- Text editor (VS Code, Notepad++, etc.)

---

## Option A: Quick Deploy (Fastest)

### Perfect for: Rapid testing, proof of concept

**Time**: ~5 minutes

### Step 1: Navigate to Repository
```powershell
cd C:\path\to\enterprise-aws-cloud-network-infrastructure
```

### Step 2: Run Quick Deploy Script
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command ". .\quick-deploy-module-00.ps1"
```

**OR** (if you have the script locally):
```powershell
.\quick-deploy-module-00.ps1
```

### Step 3: Verify & Push
```powershell
git status
git commit -m "Add Module 00: Complete AWS Traffic Flow - Quick Start"
git push origin main
```

### What Gets Created
- ✅ `00-aws-traffic-flow/README.md` (quick start guide)
- ✅ `00-aws-traffic-flow/QUICK_REFERENCE.md` (troubleshooting commands)
- ✅ `00-aws-traffic-flow/SETUP_NOTES.md` (expansion guide)

### Size: ~20 KB

---

## Option B: Full Deploy (Recommended)

### Perfect for: Production repository, complete documentation

**Time**: ~10 minutes

### Step 1: Navigate to Repository
```powershell
cd C:\path\to\enterprise-aws-cloud-network-infrastructure
```

### Step 2: Copy Deployment Script
If you don't have `deploy-module-00.ps1` yet, create it from the provided content or download from repo.

### Step 3: Run Full Deploy Script
```powershell
# Without auto-push (recommended for first time)
.\deploy-module-00.ps1

# With auto-push (if confident)
.\deploy-module-00.ps1 -AutoPush
```

### Step 4: Review & Commit
```powershell
# View what will be committed
git status

# Review the files
git diff --cached

# Commit
git commit -m "Add Module 00: Complete AWS Traffic Flow - Full Documentation"

# Push to GitHub
git push origin main
```

### What Gets Created
- ✅ `00-aws-traffic-flow/README.md` (complete 11-layer guide)
- ✅ `00-aws-traffic-flow/architecture-diagram.svg` (visual reference)
- ✅ `00-aws-traffic-flow/QUICK_REFERENCE.md` (quick troubleshooting)
- ✅ `00-aws-traffic-flow/TROUBLESHOOTING.md` (detailed layer-by-layer)

### Size: ~150 KB

### Custom Commit Message
```powershell
.\deploy-module-00.ps1 -CommitMessage "Add Module 00: AWS Traffic Flow - Production Ready" -AutoPush
```

---

## Option C: Manual Step-by-Step (Full Control)

### Perfect for: Custom modifications, learning, advanced users

**Time**: ~15 minutes

### Step 1: Create Directory Structure
```powershell
# Navigate to repo
cd C:\path\to\enterprise-aws-cloud-network-infrastructure

# Create module directory
mkdir 00-aws-traffic-flow
cd 00-aws-traffic-flow

# Create subdirectories
mkdir diagrams
mkdir examples
```

### Step 2: Create README.md
```powershell
# Create README
New-Item -Path "README.md" -ItemType File -Value @"
# 0 — Complete AWS Traffic Flow

[Paste full README content here]
[See README_REFACTORED.md for full content]
"@
```

### Step 3: Add Architecture Diagram
```powershell
# Copy the SVG file
Copy-Item -Path "..\architecture-diagram.svg" -Destination "architecture-diagram.svg"

# Verify it copied
ls architecture-diagram.svg
```

### Step 4: Create Quick Reference
```powershell
New-Item -Path "QUICK_REFERENCE.md" -ItemType File -Value @"
# Quick Reference

[Paste content here]
"@
```

### Step 5: Create Troubleshooting Guide
```powershell
New-Item -Path "TROUBLESHOOTING.md" -ItemType File -Value @"
# Troubleshooting Guide

[Paste content here]
"@
```

### Step 6: Add to Git & Commit
```powershell
# Go back to repo root
cd ..

# Add module
git add 00-aws-traffic-flow/

# Check what's being added
git status

# Commit
git commit -m "Add Module 00: Complete AWS Traffic Flow"

# Push
git push origin main
```

---

## Detailed Command Reference

### Check Current Status
```powershell
# See all changes
git status

# See diff of staged changes
git diff --cached

# See changes in specific directory
git diff --cached 00-aws-traffic-flow/
```

### Stage Files
```powershell
# Stage specific directory
git add 00-aws-traffic-flow/

# Stage all changes
git add .

# Stage specific file
git add 00-aws-traffic-flow/README.md
```

### Commit Options
```powershell
# Simple commit
git commit -m "Add Module 00"

# Detailed commit (opens editor)
git commit

# Commit all changes (including unstaged)
git commit -am "Add Module 00"

# Amend last commit
git commit --amend --no-edit
```

### Push Options
```powershell
# Push to default branch
git push

# Push to specific branch
git push origin main

# Push with force (⚠️ careful!)
git push --force-with-lease

# Push tags
git push --tags
```

### Verify Deployment
```powershell
# List files in module
ls 00-aws-traffic-flow/

# Check file sizes
ls 00-aws-traffic-flow/ -Recurse | Measure-Object -Property Length -Sum

# View README
Get-Content 00-aws-traffic-flow/README.md | head -50

# Validate markdown
# (Use online markdown validator or VS Code extension)
```

---

## Alternative: Direct Git Commands (No Scripts)

If you prefer not to use PowerShell scripts:

### Using Git Bash or WSL
```bash
# Navigate to repo
cd ~/enterprise-aws-cloud-network-infrastructure

# Create module
mkdir -p 00-aws-traffic-flow
cd 00-aws-traffic-flow

# Create files (paste content)
cat > README.md << 'EOF'
# 0 — Complete AWS Traffic Flow
...
EOF

cat > QUICK_REFERENCE.md << 'EOF'
...
EOF

# Go back and commit
cd ..
git add 00-aws-traffic-flow/
git commit -m "Add Module 00: Complete AWS Traffic Flow"
git push origin main
```

### Using GitHub Desktop
1. Open GitHub Desktop
2. Switch to your repository
3. Create `00-aws-traffic-flow` folder
4. Create `README.md`, `QUICK_REFERENCE.md`, etc.
5. Commit with message: "Add Module 00: Complete AWS Traffic Flow"
6. Push to main branch

---

## Verification Checklist

After deployment, verify everything:

### Local Verification
```powershell
# ✓ Directory exists
Test-Path 00-aws-traffic-flow

# ✓ Files exist
ls 00-aws-traffic-flow/

# ✓ README not empty
(Get-Content 00-aws-traffic-flow/README.md | Measure-Object -Line).Lines -gt 100

# ✓ SVG file copied
Test-Path 00-aws-traffic-flow/architecture-diagram.svg

# ✓ Git status clean
git status
```

### GitHub Verification
```powershell
# View on GitHub (opens browser)
start "https://github.com/vanchinathan-Cloud/enterprise-aws-cloud-network-infrastructure/tree/main/00-aws-traffic-flow"

# Or check via git
git log --oneline -5  # See recent commits
git log --all --graph --oneline  # See commit tree
```

---

## Troubleshooting

### Issue: PowerShell Script Execution Blocked

**Error**: *"File cannot be loaded because running scripts is disabled"*

**Solution**:
```powershell
# Temporarily allow execution for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run script
.\deploy-module-00.ps1
```

---

### Issue: Git Config Missing

**Error**: *"Please tell me who you are"*

**Solution**:
```powershell
# Set git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify
git config --list
```

---

### Issue: Remote Rejected Push

**Error**: *"Permission denied"* or *"Authentication failed"*

**Solution**:
```powershell
# Check remote
git remote -v

# Update remote if needed
git remote set-url origin https://github.com/YOUR-USERNAME/enterprise-aws-cloud-network-infrastructure.git

# Authenticate
git config --global credential.helper manager-core
git push origin main
# (Will prompt for authentication)
```

---

### Issue: Merge Conflicts

**Error**: *"CONFLICT (content add/add)"*

**Solution**:
```powershell
# Abort and start over
git merge --abort

# Or manually edit conflicts and resolve
git status  # See conflicted files
# Edit files, remove conflict markers
git add 00-aws-traffic-flow/
git commit -m "Resolve merge conflict"
```

---

## Pro Tips

### Tip 1: Dry Run Before Push
```powershell
# See what would be pushed without actually pushing
git push --dry-run origin main
```

### Tip 2: Verify SVG Diagram
```powershell
# Check if SVG is valid XML
[xml]$svg = Get-Content 00-aws-traffic-flow/architecture-diagram.svg
Write-Host "✓ SVG is valid XML"
```

### Tip 3: Check File Sizes
```powershell
# Ensure files aren't too large
$files = Get-ChildItem 00-aws-traffic-flow -Recurse
$files | ForEach-Object { 
    $size = $_.Length / 1KB
    Write-Host "$($_.Name): $([math]::Round($size,2)) KB"
}
```

### Tip 4: Create Multiple Commits (Granular)
```powershell
# Instead of one big commit, break it up
git add 00-aws-traffic-flow/README.md
git commit -m "Add Module 00: README"

git add 00-aws-traffic-flow/architecture-diagram.svg
git commit -m "Add Module 00: Architecture diagram"

git add 00-aws-traffic-flow/QUICK_REFERENCE.md
git commit -m "Add Module 00: Quick reference"

git push origin main
```

### Tip 5: Use Descriptive Commit Messages
```powershell
# Good ✓
git commit -m "Add Module 00: Complete AWS Traffic Flow

This module covers 11 networking layers and includes:
- Complete traffic flow explanation
- Troubleshooting guide
- Architecture diagram
- Quick reference for common issues"

# Bad ✗
git commit -m "Add module"
```

---

## Next Steps After Deployment

### 1. Test Module
```bash
# From browser, view on GitHub
open https://github.com/vanchinathan-Cloud/enterprise-aws-cloud-network-infrastructure/tree/main/00-aws-traffic-flow

# Verify all files render correctly
# Check SVG diagram displays
# Read through README for accuracy
```

### 2. Update Portfolio Docs
```markdown
# Update your repository README.md
- Add Module 00 to the module list
- Link to 00-aws-traffic-flow/README.md
- Add brief description

Example:
## Modules
- **Module 00**: Complete AWS Traffic Flow (11 layers)
- **Module 01**: VPC Networking Basics
- ... etc
```

### 3. Add to Your Personal Notes
```powershell
# Create personal implementation guide
# Document your AWS account setup
# Map actual resources to module layers
```

### 4. Proceed to Module 01
After Module 00 is confirmed working:
1. Review Module 00 (this completes!)
2. Proceed to **Module 01: VPC Networking Basics**
3. Apply concepts to your actual AWS account

---

## Summary Table

| Aspect | Option A | Option B | Option C |
|--------|----------|----------|----------|
| **Time** | 5 min | 10 min | 15 min |
| **Ease** | Easiest | Easy | Manual |
| **Files** | 3 files | 4 files | Fully customizable |
| **Size** | ~20 KB | ~150 KB | ~150 KB |
| **Best For** | Quick start | Production | Custom setup |
| **Command** | `quick-deploy-module-00.ps1` | `deploy-module-00.ps1` | Manual git |

---

## Questions?

### Common Scenarios

**Q: Can I modify files after pushing?**
A: Yes! Make changes, commit, and push again.
```powershell
# Edit files
code 00-aws-traffic-flow/README.md

# Commit changes
git add 00-aws-traffic-flow/README.md
git commit -m "Update Module 00: Fix typos"
git push origin main
```

**Q: Can I undo a commit?**
A: Yes, several ways:
```powershell
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# After push (force push - be careful!)
git push --force-with-lease origin main
```

**Q: Should I use `-AutoPush` flag?**
A: Start without it (`-AutoPush`), review files first.
```powershell
# First time (recommended)
.\deploy-module-00.ps1
# Review files, then: git commit && git push

# Subsequent times (if confident)
.\deploy-module-00.ps1 -AutoPush
```

---

**Last Updated**: September 2026  
**PowerShell Version Required**: 5.1+  
**Git Version Required**: 2.0+
