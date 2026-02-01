#!/bin/bash

# Canvas LMS Database Setup Script
# Provides multiple methods to connect Rails to PostgreSQL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Canvas LMS Database Setup Helper${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Select a setup method:"
echo ""
echo -e "${GREEN}1)${NC} Run db:initial_setup inside the web container (recommended)"
echo -e "${GREEN}2)${NC} Expose PostgreSQL port and update database.yml for host access"
echo -e "${GREEN}3)${NC} Start local PostgreSQL service (Codespace host)"
echo -e "${GREEN}4)${NC} Quick command: docker compose exec for db:initial_setup"
echo ""
echo -e "${YELLOW}0)${NC} Exit"
echo ""
read -p "Enter choice [0-4]: " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Option 1: Running db:initial_setup inside web container${NC}"
        echo "==========================================================="

        # Check if containers are running
        if ! docker compose ps --status running | grep -q "web"; then
            echo -e "${YELLOW}Starting docker compose services...${NC}"
            docker compose up -d
            echo "Waiting for services to be ready..."
            sleep 10
        fi

        echo -e "${GREEN}Executing db:initial_setup inside web container...${NC}"
        docker compose exec web bundle exec rails db:initial_setup

        echo ""
        echo -e "${GREEN}Done! Database setup completed inside container.${NC}"
        ;;

    2)
        echo ""
        echo -e "${BLUE}Option 2: Expose PostgreSQL port and update database.yml${NC}"
        echo "==========================================================="

        # Create docker-compose.override.yml to expose port
        OVERRIDE_FILE="docker-compose.override.yml"

        if [ -f "$OVERRIDE_FILE" ]; then
            echo -e "${YELLOW}Backing up existing $OVERRIDE_FILE to ${OVERRIDE_FILE}.bak${NC}"
            cp "$OVERRIDE_FILE" "${OVERRIDE_FILE}.bak"
        fi

        cat > "$OVERRIDE_FILE" << 'EOF'
# Override to expose PostgreSQL port to host
services:
  postgres:
    ports:
      - "5432:5432"
EOF

        echo -e "${GREEN}Created $OVERRIDE_FILE with port mapping${NC}"

        # Update database.yml
        DB_CONFIG="config/database.yml"
        if [ -f "$DB_CONFIG" ]; then
            echo -e "${YELLOW}Backing up $DB_CONFIG to ${DB_CONFIG}.bak${NC}"
            cp "$DB_CONFIG" "${DB_CONFIG}.bak"

            # Create updated database.yml for development
            cat > "$DB_CONFIG" << 'EOF'
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: canvas_development
  host: localhost
  username: postgres
  password: sekret

test:
  <<: *default
  database: canvas_test
  host: localhost
  username: postgres
  password: sekret

production:
  <<: *default
  database: canvas_production
  username: canvas
  password: <%= ENV['CANVAS_DATABASE_PASSWORD'] %>
EOF
            echo -e "${GREEN}Updated $DB_CONFIG with host: localhost${NC}"
        fi

        # Restart containers to apply changes
        echo -e "${YELLOW}Restarting docker compose services...${NC}"
        docker compose down
        docker compose up -d

        echo "Waiting for PostgreSQL to be ready..."
        sleep 5

        # Test connection
        echo -e "${YELLOW}Testing connection from host...${NC}"
        if pg_isready -h localhost -p 5432 -U postgres 2>/dev/null; then
            echo -e "${GREEN}PostgreSQL is accessible from host on localhost:5432${NC}"
        else
            echo -e "${YELLOW}Note: pg_isready not available, but port should be exposed${NC}"
        fi

        echo ""
        echo -e "${GREEN}Done! You can now run:${NC}"
        echo "  bundle exec rails db:initial_setup"
        ;;

    3)
        echo ""
        echo -e "${BLUE}Option 3: Start local PostgreSQL service${NC}"
        echo "==========================================="

        # Check if PostgreSQL is installed
        if ! command -v psql &> /dev/null; then
            echo -e "${RED}PostgreSQL is not installed. Installing...${NC}"
            sudo apt-get update
            sudo apt-get install -y postgresql postgresql-contrib
        fi

        # Start PostgreSQL service
        echo -e "${YELLOW}Starting local PostgreSQL service...${NC}"
        sudo service postgresql start

        # Wait for it to be ready
        sleep 3

        # Check status
        if sudo service postgresql status | grep -q "online"; then
            echo -e "${GREEN}PostgreSQL service is running${NC}"
        else
            echo -e "${YELLOW}Checking status...${NC}"
            sudo service postgresql status || true
        fi

        # Create canvas user and database
        echo -e "${YELLOW}Setting up canvas database user...${NC}"
        sudo -u postgres psql -c "CREATE USER canvas WITH PASSWORD 'canvas' CREATEDB;" 2>/dev/null || echo "User may already exist"
        sudo -u postgres psql -c "ALTER USER canvas CREATEDB;" 2>/dev/null || true

        # Update database.yml for local PostgreSQL
        DB_CONFIG="config/database.yml"
        if [ -f "$DB_CONFIG" ]; then
            echo -e "${YELLOW}Backing up $DB_CONFIG to ${DB_CONFIG}.bak${NC}"
            cp "$DB_CONFIG" "${DB_CONFIG}.bak"

            cat > "$DB_CONFIG" << 'EOF'
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: canvas_development
  host: /var/run/postgresql
  username: canvas
  password: canvas

test:
  <<: *default
  database: canvas_test
  host: /var/run/postgresql
  username: canvas
  password: canvas

production:
  <<: *default
  database: canvas_production
  username: canvas
  password: <%= ENV['CANVAS_DATABASE_PASSWORD'] %>
EOF
            echo -e "${GREEN}Updated $DB_CONFIG for local PostgreSQL${NC}"
        fi

        echo ""
        echo -e "${GREEN}Done! Local PostgreSQL is running. You can now run:${NC}"
        echo "  bundle exec rails db:initial_setup"
        ;;

    4)
        echo ""
        echo -e "${BLUE}Option 4: Quick docker compose exec command${NC}"
        echo "=============================================="

        # Check if containers are running
        if ! docker compose ps --status running 2>/dev/null | grep -q "postgres"; then
            echo -e "${YELLOW}Starting docker compose services...${NC}"
            docker compose up -d
            echo "Waiting for services to be ready..."
            sleep 10
        fi

        echo -e "${GREEN}Running: docker compose exec web bundle exec rails db:initial_setup${NC}"
        echo ""
        docker compose exec web bundle exec rails db:initial_setup

        echo ""
        echo -e "${GREEN}Done!${NC}"
        ;;

    0)
        echo "Exiting."
        exit 0
        ;;

    *)
        echo -e "${RED}Invalid option. Please run the script again.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Setup complete!${NC}"
echo -e "${BLUE}============================================${NC}"
