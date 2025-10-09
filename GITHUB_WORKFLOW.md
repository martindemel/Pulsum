# GitHub Workflow Guide for Pulsum

**A complete guide to version control, branching, pull requests, and automated code review with CodeRabbit.**

---

## Table of Contents

1. [Git & GitHub Basics](#git--github-basics)
2. [Understanding Branches](#understanding-branches)
3. [Pull Requests Explained](#pull-requests-explained)
4. [Your Daily Workflow](#your-daily-workflow)
5. [CodeRabbit Integration](#coderabbit-integration)
6. [Automated Workflows](#automated-workflows)
7. [Common Commands Reference](#common-commands-reference)
8. [Troubleshooting](#troubleshooting)

---

## Git & GitHub Basics

### What is Git?
Git is a **version control system** that tracks changes to your code over time. Think of it as a time machine for your project:
- Every commit is a snapshot of your entire project
- You can go back to any previous state
- You can see who changed what and when
- Multiple people can work on the same code without conflicts

### What is GitHub?
GitHub is a **cloud platform** that hosts Git repositories online:
- Backup your code in the cloud
- Collaborate with others
- Track issues and projects
- Automate workflows with GitHub Actions
- Review code with Pull Requests

### Key Concepts

**Repository (Repo)**: Your project folder with all its history
- Your repo: `https://github.com/martindemel/Pulsum.git`

**Commit**: A saved snapshot of your changes
- Like clicking "Save" on a document, but better
- Includes a message describing what changed
- Example: `git commit -m "feat: add user authentication"`

**Push**: Upload your commits to GitHub
- Syncs your local changes to the cloud
- Makes them visible to others

**Pull**: Download changes from GitHub
- Gets the latest code from the cloud
- Syncs others' changes to your local machine

---

## Understanding Branches

### What is a Branch?

A branch is a **separate line of development**. Imagine your project as a tree:
- The **main branch** is the trunk (stable, production-ready code)
- **Feature branches** are branches growing from the trunk (experimental work)

```
main:       A---B---C---F---G     (stable code)
                 \     /
feature/login:    D---E           (new feature)
```

### Why Use Branches?

1. **Isolation**: Work on features without breaking main
2. **Code Review**: Others can review before merging
3. **Safety**: main stays stable while you experiment
4. **History**: Clear record of when features were added

### Branch Naming Convention

Use these prefixes to organize your work:

```
feature/   - New features          (feature/user-profile)
bugfix/    - Bug fixes             (bugfix/crash-on-startup)
hotfix/    - Urgent production fix (hotfix/security-patch)
refactor/  - Code improvements     (refactor/cleanup-agents)
chore/     - Maintenance tasks     (chore/update-dependencies)
```

---

## Pull Requests Explained

### What is a Pull Request (PR)?

A Pull Request is a **request to merge** your branch into main. It's like saying:
> "Hey, I finished this feature. Can we merge it into main?"

### Why Use Pull Requests?

1. **Code Review**: Get feedback before merging
2. **Quality Control**: Catch bugs early
3. **Documentation**: Record why changes were made
4. **Testing**: Run automated tests before merging
5. **CodeRabbit**: AI reviews your code automatically

### Pull Request Lifecycle

```
1. Create feature branch      git checkout -b feature/my-feature
2. Make changes              (edit files)
3. Commit changes            git commit -m "add feature"
4. Push to GitHub            git push origin feature/my-feature
5. PR auto-created           (GitHub Actions does this)
6. CodeRabbit reviews        (AI analyzes your code)
7. Fix issues if any         (make more commits)
8. Merge to main             (manual or auto)
9. Delete branch             (cleanup)
```

---

## Your Daily Workflow

### Method 1: Feature Branch Workflow (Recommended for CodeRabbit)

This workflow enables CodeRabbit to review your code automatically.

#### Step 1: Create a Feature Branch

```bash
# Make sure you're on main and up-to-date
git checkout main
git pull origin main

# Create and switch to new feature branch
git checkout -b feature/your-feature-name
```

Example branch names:
```bash
git checkout -b feature/add-podcast-recommendations
git checkout -b bugfix/fix-agent-memory-leak
git checkout -b refactor/improve-ui-performance
```

#### Step 2: Make Your Changes

Edit your files in Xcode as usual. Write your code, test it locally.

#### Step 3: Commit Your Changes

```bash
# See what changed
git status

# Stage all changes
git add .

# Or stage specific files
git add Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift

# Commit with a descriptive message
git commit -m "feat: add podcast recommendations to CheerAgent"
```

**Commit Message Tips:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code improvement
- `docs:` - Documentation
- `test:` - Tests
- `chore:` - Maintenance

#### Step 4: Push to GitHub

```bash
git push origin feature/your-feature-name
```

#### Step 5: Automatic PR Creation ✨

**This happens automatically!** GitHub Actions will:
1. Detect your push to a feature branch
2. Create a Pull Request for you
3. Add a helpful description
4. Label it as "auto-created"

You can view it at: `https://github.com/martindemel/Pulsum/pulls`

#### Step 6: CodeRabbit Reviews 🤖

CodeRabbit will automatically:
- Analyze your code changes
- Check for bugs and issues
- Suggest improvements
- Comment on your PR with feedback

#### Step 7: Address Feedback (if any)

If CodeRabbit suggests changes:

```bash
# Make the changes in your editor
# Then commit and push again
git add .
git commit -m "fix: address CodeRabbit feedback"
git push origin feature/your-feature-name
```

The PR updates automatically! CodeRabbit will re-review.

#### Step 8: Merge to Main

**Option A: Manual Merge (Current Setup)**
1. Go to your PR on GitHub
2. Click "Merge pull request"
3. Click "Confirm merge"
4. Delete the branch

**Option B: Auto-Merge (Once Enabled)**
- PR merges automatically after approval
- Branch deleted automatically
- You don't need to do anything!

#### Step 9: Update Local Main

```bash
# Switch back to main
git checkout main

# Pull the merged changes
git pull origin main
```

Now you're ready to start your next feature! 🎉

---

### Method 2: Direct to Main (Quick Fixes Only)

For small, non-breaking changes (typos, comments, etc.):

```bash
# Make sure you're on main
git checkout main

# Make your changes
# ...

# Commit and push
git add .
git commit -m "docs: fix typo in README"
git push origin main
```

**Note**: This skips CodeRabbit review. Use sparingly!

---

## CodeRabbit Integration

### What is CodeRabbit?

CodeRabbit is an **AI-powered code reviewer** that:
- Reviews every Pull Request automatically
- Checks for bugs, security issues, and best practices
- Suggests improvements
- Learns your project over time

### How Does CodeRabbit Work?

1. **You push a branch** → GitHub detects it
2. **GitHub Action creates PR** → PR appears in your repo
3. **CodeRabbit gets notified** → Starts analyzing
4. **AI reviews your code** → Checks patterns, logic, style
5. **Comments on PR** → Posts feedback
6. **You address feedback** → Make changes
7. **CodeRabbit re-reviews** → Verifies fixes
8. **PR approved** → Ready to merge!

### Installing CodeRabbit

**Important**: You need to install the CodeRabbit GitHub App:

1. Go to: https://github.com/apps/coderabbitai
2. Click "Install"
3. Select your repository: `martindemel/Pulsum`
4. Grant permissions
5. Done! CodeRabbit is now active

**Configuration File**: `.github/coderabbit.yaml`
- Customizes how CodeRabbit reviews your code
- Focuses on Swift, SwiftUI, Core Data, etc.
- Already configured for your project

### Understanding CodeRabbit Comments

CodeRabbit will comment on your PR with:

**🟢 Positive Feedback**
> "Great use of async/await here!"

**🟡 Suggestions**
> "Consider using a weak reference to avoid retain cycle"

**🔴 Issues**
> "This could cause a crash if array is empty"

**📝 Questions**
> "Is this intentional? It changes the previous behavior."

### Responding to CodeRabbit

You can:
- **Make changes**: Address the feedback and push
- **Reply**: Explain your reasoning if you disagree
- **Resolve**: Mark the comment as resolved when fixed

CodeRabbit learns from your responses and improves over time!

---

## Automated Workflows

You have two GitHub Actions set up:

### 1. Auto-Create PR (`.github/workflows/auto-pr.yml`)

**Triggers**: When you push to any of these branches:
- `feature/*`
- `bugfix/*`
- `hotfix/*`
- `refactor/*`
- `chore/*`

**What it does**:
1. Detects new branch push
2. Checks if PR already exists
3. Creates PR if needed
4. Adds descriptive title and body
5. Labels it as "auto-created"

**Result**: You never have to manually create PRs!

### 2. Auto-Merge PR (`.github/workflows/auto-merge.yml`)

**Status**: Currently DISABLED for safety

**When enabled, it**:
1. Waits for CodeRabbit approval
2. Checks all tests pass
3. Automatically merges PR
4. Deletes the branch

**To enable**:
1. Open `.github/workflows/auto-merge.yml`
2. Uncomment lines 6-10
3. Comment out line 13
4. Commit and push

**Why disabled?**: You may want to review manually at first. Enable when comfortable!

---

## Common Commands Reference

### Starting a New Feature

```bash
git checkout main
git pull origin main
git checkout -b feature/my-new-feature
```

### Saving Your Work

```bash
git status                    # See what changed
git add .                     # Stage all changes
git add file.swift            # Stage specific file
git commit -m "message"       # Commit with message
git push origin branch-name   # Push to GitHub
```

### Viewing Status

```bash
git status                    # Current changes
git log                       # Commit history
git log --oneline             # Compact history
git branch                    # List local branches
git branch -a                 # List all branches
```

### Switching Branches

```bash
git checkout main             # Switch to main
git checkout feature/login    # Switch to feature branch
git checkout -b new-branch    # Create and switch
```

### Updating Your Code

```bash
git pull origin main          # Get latest from main
git fetch origin              # Download all branches
git merge main                # Merge main into current branch
```

### Undoing Changes

```bash
git restore file.swift        # Discard uncommitted changes
git reset HEAD~1              # Undo last commit (keep changes)
git reset --hard HEAD~1       # Undo last commit (delete changes)
```

⚠️ **Warning**: `--hard` deletes changes permanently!

### Viewing Changes

```bash
git diff                      # Uncommitted changes
git diff main                 # Compare to main
git diff HEAD~1               # Compare to previous commit
```

### Cleaning Up

```bash
git branch -d feature/old     # Delete local branch
git push origin --delete feature/old  # Delete remote branch
```

---

## Troubleshooting

### Problem: Can't push to GitHub

**Error**: `Permission denied` or `Authentication failed`

**Solution**:
```bash
# Check your remote URL
git remote -v

# Should show HTTPS URL with your username
# If not, update it:
git remote set-url origin https://github.com/martindemel/Pulsum.git
```

Or use SSH:
```bash
git remote set-url origin git@github.com:martindemel/Pulsum.git
```

---

### Problem: Merge conflicts

**What happened**: Two branches changed the same lines

**Solution**:
```bash
# Update your branch with main
git checkout feature/your-branch
git pull origin main

# Git will mark conflicts in files
# Open conflicting files in Xcode
# You'll see markers like:
<<<<<<< HEAD
your changes
=======
changes from main
>>>>>>> main

# Edit the file to resolve
# Keep the version you want
# Remove the conflict markers

# Then commit the resolution
git add .
git commit -m "fix: resolve merge conflicts"
git push origin feature/your-branch
```

---

### Problem: CodeRabbit not reviewing

**Possible causes**:
1. CodeRabbit not installed
2. PR not created yet
3. No permissions

**Solutions**:
1. Install CodeRabbit app (see [Installing CodeRabbit](#installing-coderabbit))
2. Wait a few minutes - it can take time
3. Check PR has "auto-created" label
4. Verify `.github/coderabbit.yaml` exists

---

### Problem: PR not auto-created

**Check**:
```bash
# Did you push to a feature branch?
git branch  # Should show feature/* or bugfix/* etc.

# If on main, create a feature branch
git checkout -b feature/my-feature
git push origin feature/my-feature
```

---

### Problem: Accidentally committed to main

**Solution 1**: Create a feature branch from current state
```bash
# Create branch with your changes
git branch feature/my-changes

# Reset main to previous commit
git reset --hard HEAD~1

# Switch to feature branch
git checkout feature/my-changes

# Push the feature branch
git push origin feature/my-changes
```

**Solution 2**: Just push to main (for small changes)
```bash
# It's okay sometimes!
git push origin main
```

---

### Problem: Forgot to pull before making changes

**Solution**: Stash, pull, then re-apply
```bash
# Save your changes temporarily
git stash

# Pull latest
git pull origin main

# Re-apply your changes
git stash pop

# If conflicts, resolve them
```

---

### Problem: Want to undo a merged PR

**Solution**: Revert the merge
```bash
# Find the merge commit hash
git log --oneline

# Revert it (creates a new commit that undoes it)
git revert -m 1 <merge-commit-hash>

# Push the revert
git push origin main
```

---

## Quick Reference Card

### Daily Workflow (Solo Developer)

```bash
# 1. Start new feature
git checkout main && git pull origin main
git checkout -b feature/amazing-feature

# 2. Make changes in Xcode
# ... edit files ...

# 3. Commit
git add .
git commit -m "feat: add amazing feature"

# 4. Push (auto-creates PR)
git push origin feature/amazing-feature

# 5. Wait for CodeRabbit review
# Check: https://github.com/martindemel/Pulsum/pulls

# 6. Address feedback if needed
git add .
git commit -m "fix: apply CodeRabbit suggestions"
git push origin feature/amazing-feature

# 7. Merge PR on GitHub (manual or auto)

# 8. Update local main
git checkout main && git pull origin main

# 9. Repeat!
```

---

## Advanced Tips

### Commit Often, Push Regularly

```bash
# Good practice: Commit after each logical change
git commit -m "feat: add user model"
git commit -m "feat: add user service"
git commit -m "feat: add user UI"

# Push at end of day or when feature is complete
git push origin feature/user-management
```

### Write Good Commit Messages

```bash
# ❌ Bad
git commit -m "fixed stuff"
git commit -m "updates"

# ✅ Good
git commit -m "fix: resolve crash when user logs out"
git commit -m "feat: add dark mode support to settings"
git commit -m "refactor: extract duplicate code into helper"
```

### Use .gitignore

Already set up in your project! It prevents committing:
- Build artifacts
- Xcode user files
- API keys
- Temporary files

### Check Before You Commit

```bash
# Always review what you're committing
git status
git diff

# Then commit
git add .
git commit -m "your message"
```

### Branch Naming is Important

```bash
# ✅ Good
feature/add-podcast-search
bugfix/fix-agent-crash
refactor/cleanup-ui-code

# ❌ Bad
test
fix
asdf
branch1
```

Good names trigger auto-PR creation!

---

## GitHub Web Interface

### Viewing Your Repository

`https://github.com/martindemel/Pulsum`

**Tabs**:
- **Code**: Browse files and folders
- **Issues**: Track bugs and features
- **Pull Requests**: See all PRs
- **Actions**: View workflow runs
- **Settings**: Configure repository

### Viewing Pull Requests

`https://github.com/martindemel/Pulsum/pulls`

On a PR page you'll see:
- **Conversation**: Comments and reviews
- **Commits**: All commits in the PR
- **Files changed**: Diff view of changes
- **Checks**: Status of GitHub Actions

### Merging a Pull Request

1. Go to PR page
2. Check CodeRabbit's review
3. Click "Merge pull request"
4. Choose merge method:
   - **Squash and merge**: Combines all commits (recommended)
   - **Merge commit**: Keeps all commits
   - **Rebase and merge**: Linear history
5. Click "Confirm merge"
6. Click "Delete branch"

---

## What's Next?

### After Setup

1. **Install CodeRabbit**: Follow instructions in [CodeRabbit Integration](#installing-coderabbit)
2. **Test the workflow**: Create a test feature branch and push it
3. **Watch CodeRabbit work**: See it review your first PR
4. **Get comfortable**: Use this workflow for a few weeks
5. **Enable auto-merge**: Once confident, enable auto-merge workflow

### Learning More

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [CodeRabbit Docs](https://docs.coderabbit.ai/)
- [Swift Style Guide](https://swift.org/documentation/)

---

## Summary

### What You Have Now

✅ **Version Control**: All changes tracked in Git  
✅ **Cloud Backup**: Code stored on GitHub  
✅ **Feature Branches**: Isolated development  
✅ **Pull Requests**: Code review process  
✅ **AI Code Review**: CodeRabbit automated reviews  
✅ **Auto-PR Creation**: No manual PR creation needed  
✅ **Auto-Merge**: (Optional) Hands-free merging  

### Your Workflow in One Sentence

**Create feature branch → Make changes → Push → Auto-PR created → CodeRabbit reviews → Merge → Done!**

---

## Questions?

If you run into issues:
1. Check [Troubleshooting](#troubleshooting) section
2. Look at GitHub Actions logs (Actions tab)
3. Check PR comments for hints
4. Google the error message

Remember: Git is forgiving. Most mistakes can be undone!

---

**Happy coding!** 🚀

*Last updated: October 9, 2025*

