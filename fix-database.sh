#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Pulsum Database Fix Script ===${NC}"

# Run the column addition script
echo -e "${GREEN}Adding use_dexcom column to users table...${NC}"
node backend/scripts/add-dexcom-column.js

# Re-initialize the database
echo -e "${GREEN}Reinitializing database with the updated schema...${NC}"
npm run init-db

echo -e "${GREEN}Database fix completed. You can now restart your application.${NC}"
echo -e "${YELLOW}Run 'npm run dev' to start the application.${NC}" 