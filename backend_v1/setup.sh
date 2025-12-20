#!/bin/bash

# Fedha Backend Setup Script
# This script automates the setup of the Django backend

set -e  # Exit on error

echo "================================"
echo "Fedha Backend Setup"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Python 3 is installed
if ! command -v python &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3.8+${NC}"
    exit 1
fi

echo -e "${GREEN}Python 3 is installed.${NC}"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}PostgreSQL is not installed. Please install PostgreSQL 12+${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python and PostgreSQL found${NC}"
echo ""

# Create virtual environment
echo -e "${YELLOW}Creating virtual environment...${NC}"
python -m venv venv
source venv/scripts/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install django djangorestframework psycopg2-binary django-cors-headers \
    python-decouple djangorestframework-simplejwt django-filter PyJWT

# Create requirements.txt
# pip freeze > requirements.txt
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOF
# Django settings
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_NAME=fedha_db
DB_USER=postgres
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=5432

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Email (optional)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@fedha.app
EOF
    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${YELLOW}Please update .env with your PostgreSQL password${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi
echo ""

# Database setup
echo -e "${YELLOW}Setting up database...${NC}"
read -p "Enter PostgreSQL password: " -s DB_PASSWORD
echo ""

# Create database
echo -e "${YELLOW}Creating database 'fedha_db'...${NC}"
PGPASSWORD=$DB_PASSWORD psql -U postgres -c "CREATE DATABASE fedha_db;" 2>/dev/null || echo "Database may already exist"

# Run schema
if [ -f schema.sql ]; then
    echo -e "${YELLOW}Running database schema...${NC}"
    PGPASSWORD=$DB_PASSWORD psql -U postgres -d fedha_db -f schema.sql
    echo -e "${GREEN}✓ Database schema created${NC}"
else
    echo -e "${YELLOW}schema.sql not found. Please run it manually.${NC}"
fi
echo ""

# Create Django project if it doesn't exist
if [ ! -f manage.py ]; then
    echo -e "${YELLOW}Creating Django project...${NC}"
    django-admin startproject fedha_backend .
    echo -e "${GREEN}✓ Django project created${NC}"
fi
echo ""

# Create apps if they don't exist
APPS=("accounts" "transactions" "goals" "budgets" "invoicing" "sync")
for app in "${APPS[@]}"; do
    if [ ! -d "$app" ]; then
        echo -e "${YELLOW}Creating $app app...${NC}"
        python manage.py startapp $app
        echo -e "${GREEN}✓ $app app created${NC}"
    fi
done
echo ""

# Create logs directory
mkdir -p logs
echo -e "${GREEN}✓ Logs directory created${NC}"
echo ""

# Run migrations
echo -e "${YELLOW}Running migrations...${NC}"
python manage.py makemigrations
python manage.py migrate
echo -e "${GREEN}✓ Migrations completed${NC}"
echo ""

# Create superuser
echo -e "${YELLOW}Create superuser account${NC}"
echo "Press Ctrl+C to skip..."
python manage.py createsuperuser || echo "Skipped superuser creation"
echo ""

# Collect static files
echo -e "${YELLOW}Collecting static files...${NC}"
python manage.py collectstatic --noinput
echo -e "${GREEN}✓ Static files collected${NC}"
echo ""

echo "================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Update .env with your database password"
echo "2. Run: source venv/bin/activate"
echo "3. Run: python manage.py runserver"
echo "4. Visit: http://localhost:8000/api/"
echo ""
echo "Admin panel: http://localhost:8000/admin/"
echo "API Documentation: http://localhost:8000/api/"
echo ""