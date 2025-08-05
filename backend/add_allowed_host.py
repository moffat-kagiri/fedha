#!/usr/bin/env python
"""
Script to add new hosts to Django's ALLOWED_HOSTS setting.
Usage:
    python add_allowed_host.py domain1 [domain2 ...]
    
Example:
    python add_allowed_host.py new-tunnel-123.trycloudflare.com another-domain.com
"""

import os
import re
import sys
from pathlib import Path


def find_settings_file():
    """Find Django settings.py file in the backend directory."""
    backend_dir = Path(os.path.dirname(os.path.abspath(__file__)))
    
    # Try both possible locations (project named 'backend' or settings in 'backend' folder)
    candidates = [
        backend_dir / "settings.py",
        backend_dir / "backend" / "settings.py",
        backend_dir / "fedha" / "settings.py"
    ]
    
    for candidate in candidates:
        if candidate.exists():
            return candidate
            
    return None


def add_allowed_hosts(settings_path, new_hosts):
    """Add new hosts to ALLOWED_HOSTS in Django settings file."""
    if not settings_path.exists():
        print(f"Error: Settings file not found at {settings_path}")
        return False
        
    with open(settings_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find ALLOWED_HOSTS in the file
    allowed_hosts_pattern = r"ALLOWED_HOSTS\s*=\s*\[([\s\S]*?)\]"
    match = re.search(allowed_hosts_pattern, content)
    
    if not match:
        print("Error: Could not find ALLOWED_HOSTS in settings.py")
        return False
    
    # Extract the current hosts
    hosts_content = match.group(1)
    
    # Parse existing hosts
    host_pattern = r"['\"](.*?)['\"]"
    existing_hosts = re.findall(host_pattern, hosts_content)
    
    # Add new hosts if they don't already exist
    hosts_added = []
    for host in new_hosts:
        if host not in existing_hosts:
            hosts_added.append(host)
    
    if not hosts_added:
        print("All specified hosts are already in ALLOWED_HOSTS")
        return True
    
    # Format new hosts with proper indentation
    indent = ' ' * 4  # Standard indentation
    formatted_new_hosts = ',\n'.join(f"{indent}'{host}'  # Added by script" for host in hosts_added)
    
    # Insert the new hosts before the closing bracket
    closing_bracket_pos = match.start() + len("ALLOWED_HOSTS = [") + len(hosts_content)
    new_content = (
        content[:closing_bracket_pos] + 
        ("," if hosts_content.strip() else "") + 
        "\n" + formatted_new_hosts + 
        content[closing_bracket_pos:]
    )
    
    # Write the updated content back
    with open(settings_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"Successfully added {', '.join(hosts_added)} to ALLOWED_HOSTS")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} domain1 [domain2 ...]")
        sys.exit(1)
    
    settings_path = find_settings_file()
    if not settings_path:
        print("Error: Could not find Django settings.py file")
        sys.exit(1)
        
    print(f"Found settings file at: {settings_path}")
    
    new_hosts = sys.argv[1:]
    success = add_allowed_hosts(settings_path, new_hosts)
    
    sys.exit(0 if success else 1)
