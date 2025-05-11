#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Running pre-commit security check..."

# Check for .env files
if git diff --cached --name-only | grep -q ".env$"; then
  echo -e "${RED}❌ ERROR: Attempting to commit .env file with credentials${NC}"
  echo -e "Run: git reset .env"
  exit 1
fi

# Check for database files
if git diff --cached --name-only | grep -q ".db$"; then
  echo -e "${RED}❌ ERROR: Attempting to commit database file${NC}"
  echo -e "These files may contain personal health data and should not be committed."
  echo -e "Run: git reset -- \"*.db\""
  exit 1
fi

# Check for potential API keys in staged files
APIKEY_PATTERN="(api[_-]?key|apikey|access[_-]?key|auth[_-]?key|client[_-]?secret|secret[_-]?key|token)[=\"'\s:]+[A-Za-z0-9_\-]{16,}"
if git diff --cached -G "$APIKEY_PATTERN" --name-only | grep -v "\.gitignore\|\.example\|README"; then
  echo -e "${YELLOW}⚠️  WARNING: Possible API keys or secrets found in staged files${NC}"
  echo -e "Please review the files above and remove any API keys before committing"
  echo -e "Run: git diff --cached to review changes"
  echo -e "${YELLOW}Do you want to continue with the commit? (y/n)${NC}"
  read -r response
  if [[ "$response" != "y" ]]; then
    exit 1
  fi
fi

echo -e "${GREEN}✅ No obvious security issues found${NC}"
exit 0 