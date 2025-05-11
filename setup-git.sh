#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==== Setting up Git repository for Pulsum Wellness App ====${NC}"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed. Please install Git and try again.${NC}"
    exit 1
fi

# Check if already in a git repository
if [ -d ".git" ]; then
    echo -e "${YELLOW}This directory is already a Git repository.${NC}"
    echo -e "Running safety checks..."
else
    # Initialize git repository
    echo -e "${GREEN}Initializing Git repository...${NC}"
    git init
fi

# Install pre-commit hook
echo -e "${GREEN}Setting up pre-commit hook...${NC}"
if [ -f "pre-commit-check.sh" ]; then
    # Check if hooks directory exists
    if [ ! -d ".git/hooks" ]; then
        mkdir -p .git/hooks
    fi
    
    # Create pre-commit hook that runs our script
    cat > .git/hooks/pre-commit << EOF
#!/bin/bash
./pre-commit-check.sh
EOF
    
    # Make it executable
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}Pre-commit hook installed successfully.${NC}"
else
    echo -e "${RED}pre-commit-check.sh not found. Please run the setup again.${NC}"
    exit 1
fi

# Check for .env file
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Warning: .env file detected.${NC}"
    echo -e "This file contains your API keys and secrets and should not be committed to Git."
    echo -e "It has been added to .gitignore, but we'll make sure it's not tracked."
    
    # Stage .gitignore first to ensure .env is ignored
    git add .gitignore
    
    # Make git forget about .env if it's being tracked
    git rm --cached .env 2>/dev/null || true
    
    echo -e "${GREEN}✅ .env file is now ignored by Git.${NC}"
fi

# Verify .db files will be ignored
echo -e "${GREEN}Verifying database files will be ignored...${NC}"
if grep -q "*.db" .gitignore && grep -q "/db/*.db" .gitignore; then
    echo -e "${GREEN}✅ Database files are properly excluded in .gitignore.${NC}"
else
    echo -e "${YELLOW}Adding database exclusions to .gitignore...${NC}"
    echo -e "\n# Database files\n*.db\n*.sqlite\n*.sqlite3\n/db/*.db" >> .gitignore
    echo -e "${GREEN}✅ Database exclusions added to .gitignore.${NC}"
fi

echo -e "${GREEN}✅ Git repository is now set up safely.${NC}"
echo -e "${YELLOW}You can now add your files with: git add .${NC}"
echo -e "${YELLOW}Then commit with: git commit -m \"Initial commit\"${NC}"
echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}IMPORTANT: Before pushing to GitHub, run:${NC}"
echo -e "${YELLOW}./pre-commit-check.sh${NC}"
echo -e "${YELLOW}to verify no sensitive data will be pushed.${NC}" 