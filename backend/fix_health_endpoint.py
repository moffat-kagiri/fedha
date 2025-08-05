import os
import sys
from pathlib import Path
import re

def find_urls_file():
    """Find the main urls.py file in the Django project."""
    # Common locations for main urls.py
    backend_dir = Path(os.path.abspath(__file__)).parent
    
    candidates = [
        backend_dir / "fedha" / "urls.py",
        backend_dir / "backend" / "urls.py",
        backend_dir / "urls.py",
    ]
    
    for candidate in candidates:
        if candidate.exists():
            return candidate
    
    return None

def check_health_endpoint(urls_file):
    """Check if the health endpoint is included in the main urls.py file."""
    if not urls_file:
        print("Could not find main urls.py file.")
        return False
    
    with open(urls_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Look for health endpoint pattern
    health_patterns = [
        r"path\(['\"]api/health/?['\"]",
        r"include\(['\"]api\.health\.urls['\"]",
        r"include\(['\"]health\.urls['\"]"
    ]
    
    for pattern in health_patterns:
        if re.search(pattern, content):
            print(f"✅ Health endpoint found in {urls_file}")
            return True
    
    print(f"❌ Health endpoint not found in {urls_file}")
    return False

def add_health_endpoint(urls_file):
    """Add health endpoint to the main urls.py file."""
    if not urls_file:
        return False
    
    with open(urls_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Look for urlpatterns
    match = re.search(r'urlpatterns\s*=\s*\[', content)
    if not match:
        print("Could not find urlpatterns in urls.py")
        return False
    
    # Add check_health import at the top
    import_stmt = "from check_health import health_check\n"
    if "check_health" not in content:
        # Find last import statement
        imports_end = 0
        for match in re.finditer(r'^\s*(import|from)\s+', content, re.MULTILINE):
            imports_end = max(imports_end, match.end())
        
        # Insert our import after the last import
        content = content[:imports_end] + import_stmt + content[imports_end:]
    
    # Find position to add the health endpoint
    insert_pos = content.find(']', match.end())
    if insert_pos == -1:
        print("Could not find where to add the health endpoint")
        return False
    
    # Add the health endpoint
    health_path = "\n    path('api/health/', health_check, name='health_check'),"
    content = content[:insert_pos] + health_path + content[insert_pos:]
    
    # Write the updated content
    with open(urls_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Added health endpoint to {urls_file}")
    return True

def main():
    print("Checking Django URL configuration...")
    urls_file = find_urls_file()
    
    if not urls_file:
        print("Could not find main urls.py file. Make sure you're running this script from the Django project root.")
        return
    
    print(f"Found main URLs file at: {urls_file}")
    
    # Check if health endpoint is already configured
    if check_health_endpoint(urls_file):
        print("Health endpoint is already configured.")
    else:
        print("Health endpoint is not configured. Adding it...")
        if add_health_endpoint(urls_file):
            print("Health endpoint added successfully!")
        else:
            print("Failed to add health endpoint.")

if __name__ == "__main__":
    main()
