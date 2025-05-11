#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Pulsum Wellness App Requirements Installer ===${NC}"

# Create necessary directories
mkdir -p db
mkdir -p data
mkdir -p logs

# Check Node.js version
echo -e "${GREEN}Checking Node.js installation...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed.${NC}"
    echo -e "${YELLOW}Please install Node.js v16 or higher from https://nodejs.org/${NC}"
    exit 1
else
    NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        echo -e "${YELLOW}Warning: Node.js version $NODE_VERSION detected. Pulsum requires Node.js v16 or higher.${NC}"
        echo -e "${YELLOW}Please upgrade your Node.js installation.${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Node.js v$(node -v) is installed.${NC}"
    fi
fi

# Check npm version
echo -e "${GREEN}Checking npm installation...${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed.${NC}"
    echo -e "${YELLOW}It should come with Node.js. Please check your installation.${NC}"
    exit 1
else
    NPM_VERSION=$(npm -v | cut -d '.' -f 1)
    if [ "$NPM_VERSION" -lt 8 ]; then
        echo -e "${YELLOW}Warning: npm version $NPM_VERSION detected. Pulsum works best with npm v8 or higher.${NC}"
        echo -e "${YELLOW}Consider upgrading: npm install -g npm@latest${NC}"
    else
        echo -e "${GREEN}✓ npm v$(npm -v) is installed.${NC}"
    fi
fi

# Check for .env file or create from example
echo -e "${GREEN}Checking for environment configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}No .env file found. Creating from .env.example...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}Created .env file. Please edit it to add your API keys.${NC}"
    else
        echo -e "${RED}No .env.example file found. Cannot set up environment.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ .env file exists.${NC}"
fi

# Install root dependencies
echo -e "${GREEN}Installing main dependencies...${NC}"
npm install || { 
    echo -e "${RED}Failed to install main dependencies.${NC}"; 
    exit 1; 
}

# Install frontend dependencies
echo -e "${GREEN}Installing frontend dependencies...${NC}"
cd frontend && npm install && cd .. || {
    echo -e "${RED}Failed to install frontend dependencies.${NC}";
    exit 1;
}

# Initialize database
echo -e "${GREEN}Initializing database...${NC}"
npm run init-db || { 
    echo -e "${RED}Failed to initialize database.${NC}"; 
    echo -e "${YELLOW}Trying again after a short delay...${NC}"; 
    sleep 2; 
    npm run init-db || { 
        echo -e "${RED}Database initialization failed again.${NC}"; 
        exit 1; 
    }
}

# Install git hooks if git is available
if command -v git &> /dev/null && [ -d ".git" ]; then
    echo -e "${GREEN}Setting up git pre-commit hooks...${NC}"
    if [ -f "pre-commit-check.sh" ]; then
        # Check if hooks directory exists
        if [ ! -d ".git/hooks" ]; then
            mkdir -p .git/hooks
        fi
        
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << EOF
#!/bin/bash
./pre-commit-check.sh
EOF
        
        # Make it executable
        chmod +x .git/hooks/pre-commit
        echo -e "${GREEN}✓ Git pre-commit hook set up.${NC}"
    fi
fi

# Check if OpenAI API key is set
if grep -q "OPENAI_API_KEY=your_openai_api_key_here" .env; then
    echo -e "${YELLOW}Warning: You need to set your OpenAI API key in the .env file.${NC}"
fi

# Check if Oura token is set
if grep -q "OURA_PERSONAL_TOKEN=your_oura_token_here" .env; then
    echo -e "${YELLOW}Warning: You need to set your Oura Personal Token in the .env file.${NC}"
fi

echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo -e "${GREEN}All requirements have been installed.${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Edit the .env file to add your API keys"
echo -e "2. Start the application with: ${GREEN}npm run dev${NC}"
echo -e "3. Access the application at: ${GREEN}http://localhost:3000${NC}" 