#!/bin/bash
# Pre-commit hook script for code quality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Running pre-commit checks...${NC}"

# Check if we're in the backend directory
if [ ! -f "manage.py" ]; then
    echo -e "${RED}❌ Error: Run this script from the backend directory${NC}"
    exit 1
fi

# Initialize error flag
ERRORS=0

# 1. Check Django models
echo -e "\n${YELLOW}📋 Checking Django models...${NC}"
if python manage.py check --quiet; then
    echo -e "${GREEN}✅ Django check passed${NC}"
else
    echo -e "${RED}❌ Django check failed${NC}"
    ERRORS=1
fi

# 2. Check for migration issues
echo -e "\n${YELLOW}🔄 Checking for pending migrations...${NC}"
if python manage.py makemigrations --dry-run --check &>/dev/null; then
    echo -e "${GREEN}✅ No pending migrations${NC}"
else
    echo -e "${YELLOW}⚠️ Pending migrations detected${NC}"
    python manage.py makemigrations --dry-run
fi

# 3. Run Python syntax check
echo -e "\n${YELLOW}🐍 Checking Python syntax...${NC}"
if python -m py_compile api/models.py api/views.py api/serializers.py; then
    echo -e "${GREEN}✅ Python syntax check passed${NC}"
else
    echo -e "${RED}❌ Python syntax errors found${NC}"
    ERRORS=1
fi

# 4. Format code with Black (if available)
if command -v black &> /dev/null; then
    echo -e "\n${YELLOW}🎨 Formatting code with Black...${NC}"
    black --check --diff api/ || {
        echo -e "${YELLOW}⚠️ Code formatting issues found. Run 'black api/' to fix${NC}"
    }
else
    echo -e "${YELLOW}⚠️ Black not installed. Install with: pip install black${NC}"
fi

# 5. Sort imports with isort (if available)
if command -v isort &> /dev/null; then
    echo -e "\n${YELLOW}📝 Checking import sorting...${NC}"
    isort --check-only --diff api/ || {
        echo -e "${YELLOW}⚠️ Import sorting issues found. Run 'isort api/' to fix${NC}"
    }
else
    echo -e "${YELLOW}⚠️ isort not installed. Install with: pip install isort${NC}"
fi

# 6. Run flake8 linting (if available)
if command -v flake8 &> /dev/null; then
    echo -e "\n${YELLOW}🔍 Running flake8 linting...${NC}"
    flake8 api/ || {
        echo -e "${YELLOW}⚠️ Linting issues found${NC}"
    }
else
    echo -e "${YELLOW}⚠️ flake8 not installed. Install with: pip install flake8${NC}"
fi

# Summary
echo -e "\n${YELLOW}📊 Summary:${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo -e "${GREEN}🚀 Ready for commit${NC}"
else
    echo -e "${RED}❌ Some critical checks failed${NC}"
    echo -e "${RED}🛑 Please fix errors before committing${NC}"
fi

exit $ERRORS
