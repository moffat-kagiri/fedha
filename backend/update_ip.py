import socket
import re
import os
from pathlib import Path

def get_local_ip():
    """Get the local IP address of the machine."""
    try:
        # Create a socket connection to an external server
        # This doesn't actually establish a connection
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Doesn't even have to be reachable
        s.connect(('8.8.8.8', 1))
        IP = s.getsockname()[0]
        s.close()
        return IP
    except:
        return '127.0.0.1'  # Fallback to localhost

def update_settings_with_ip(ip_address):
    """Update Django settings.py with the correct IP."""
    # Find the settings file
    settings_path = Path(__file__).resolve().parent / 'fedha' / 'settings.py'
    
    if not settings_path.exists():
        print(f"Error: Settings file not found at {settings_path}")
        return False
    
    # Read the file
    with open(settings_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Look for the IP address pattern in ALLOWED_HOSTS
    pattern = r"'192\.168\.\d+\.\d+',\s*#\s*Your local network IP"
    
    # Prepare replacement
    replacement = f"'{ip_address}',  # Your local network IP"
    
    # Check if we found a match
    if re.search(pattern, content):
        # Replace the existing IP
        new_content = re.sub(pattern, replacement, content)
    else:
        # If no match found, try to find ALLOWED_HOSTS list and add it there
        allowed_hosts_pattern = r"(ALLOWED_HOSTS\s*=\s*\[[\s\S]*?\])"
        match = re.search(allowed_hosts_pattern, content)
        if match:
            # Add the new IP before the closing bracket
            hosts_list = match.group(1)
            closing_bracket_pos = hosts_list.rfind(']')
            new_hosts_list = (
                hosts_list[:closing_bracket_pos] +
                f"\n    '{ip_address}',  # Your local network IP" +
                hosts_list[closing_bracket_pos:]
            )
            new_content = content.replace(hosts_list, new_hosts_list)
        else:
            print("Could not find ALLOWED_HOSTS in settings.py")
            return False
    
    # Write the updated content
    with open(settings_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    return True

if __name__ == "__main__":
    local_ip = get_local_ip()
    print(f"Your local IP address is: {local_ip}")
    
    if update_settings_with_ip(local_ip):
        print(f"Successfully updated settings.py with your IP: {local_ip}")
    else:
        print("Failed to update settings.py")
