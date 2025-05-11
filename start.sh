#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Pulsum Wellness App Startup Script ===${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js v16 or higher.${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo -e "${YELLOW}Warning: Node.js version $NODE_VERSION detected. Pulsum works best with Node.js v16 or higher.${NC}"
fi

# Create necessary directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p db
mkdir -p data
mkdir -p logs

# Check if data/microaction.json exists
if [ ! -f data/microaction.json ]; then
    echo -e "${YELLOW}Warning: microaction.json not found in data directory.${NC}"
    echo -e "${YELLOW}The app will use fallback recommendations.${NC}"
else
    echo -e "${GREEN}Found microaction.json data file.${NC}"
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}No .env file found. Creating from .env.example...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}Created .env file. Please make sure your API details are correctly set.${NC}"
    else
        # Create minimal .env file
        echo -e "${YELLOW}Creating minimal .env file. Please update with your API keys.${NC}"
        cat > .env << EOF
# API Keys
OPENAI_API_KEY=your_openai_api_key_here
OURA_PERSONAL_TOKEN=your_oura_token_here

# Server Configuration
PORT=3001
NODE_ENV=development
JWT_SECRET=pulsum_random_secret_key_12345

# Database Configuration
DB_PATH=./db/pulsum.db
EOF
        echo -e "${GREEN}Created minimal .env file. Please update it with your API keys.${NC}"
    fi
else
    echo -e "${GREEN}Found .env file.${NC}"
fi

# Installing dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install || { echo -e "${RED}Failed to install backend dependencies${NC}"; exit 1; }

# Check if frontend/node_modules exists to avoid unnecessary reinstallation
if [ ! -d "frontend/node_modules" ]; then
    echo -e "${GREEN}Installing frontend dependencies...${NC}"
    cd frontend && npm install && cd ..
else
    echo -e "${GREEN}Frontend dependencies already installed.${NC}"
fi

echo -e "${GREEN}Dependencies installed successfully.${NC}"

# Initialize database
echo -e "${GREEN}Initializing database...${NC}"
npm run init-db || { 
    echo -e "${RED}Failed to initialize database. Trying again after a short delay...${NC}"; 
    sleep 2; 
    npm run init-db || { 
        echo -e "${RED}Database initialization failed again. Please check your database configuration.${NC}"; 
        exit 1; 
    }
}
echo -e "${GREEN}Database initialized successfully.${NC}"

# Start the application
echo -e "${GREEN}Starting Pulsum Wellness App...${NC}"
echo -e "${YELLOW}The app will be available at http://localhost:3000${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the servers${NC}"
npm run dev 