#!/usr/bin/env python3
"""
API Configuration Updater for Fedha App
Updates the API configuration in the Flutter app to use a tunnel URL
"""

import os
import sys
import re
from pathlib import Path

def find_api_config_file():
    """Find the API config file in the Flutter app"""
    # Start from current directory and go up to find the app directory
    current_dir = Path.cwd()
    
    # First try to find the app directory from the current directory
    app_dir = None
    search_dir = current_dir
    
    # Search up to 3 levels up
    for _ in range(3):
        if (search_dir / "app").exists() and (search_dir / "app").is_dir():
            app_dir = search_dir / "app"
            break
        if search_dir.parent == search_dir:  # At root
            break
        search_dir = search_dir.parent
    
    if not app_dir:
        # If still not found, assume we're in the backend directory
        # and the app directory is at the same level
        app_dir = current_dir.parent / "app"
        
    if not app_dir.exists():
        print(f"❌ Could not find the app directory")
        return None
        
    # Now look for the API config file
    # First check if lib/services/api/api_config.dart exists
    api_config_path = app_dir / "lib" / "services" / "api" / "api_config.dart"
    if api_config_path.exists():
        return api_config_path
        
    # If not found, search for it
    for root, _, files in os.walk(app_dir / "lib"):
        for file in files:
            if file == "api_config.dart":
                return Path(root) / file
                
    print("❌ Could not find api_config.dart file")
    return None

def update_api_config(api_config_path, tunnel_url):
    """Update the API configuration to use the tunnel URL"""
    if not tunnel_url.startswith("http"):
        tunnel_url = f"https://{tunnel_url}"
        
    # Read the current file content
    content = api_config_path.read_text()
    
    # Check if the file already contains the tunnel URL
    if tunnel_url in content:
        print(f"✅ API config already contains the tunnel URL: {tunnel_url}")
        return True
        
    # Backup the file
    backup_path = api_config_path.with_suffix(".dart.bak")
    backup_path.write_text(content)
    print(f"📝 Created backup at {backup_path}")
    
    # Update the development configuration
    # Look for something like:
    # factory ApiConfig.development() {
    #   return ApiConfig(
    #     primaryBaseUrl: 'https://...',
    #     ...
    # }
    
    dev_config_pattern = r"(factory\s+ApiConfig\.development\(\)\s*{[^}]*return\s+ApiConfig\(\s*primaryBaseUrl:\s*['\"])([^'\"]+)(['\"]\s*,)"
    new_content = re.sub(dev_config_pattern, rf"\1{tunnel_url}\3", content)
    
    # If the pattern wasn't found or didn't match as expected, show error
    if new_content == content:
        print("❌ Could not find development configuration to update")
        
        # Try a more general approach - replace any URL that looks like a base URL
        url_pattern = r"(https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b[-a-zA-Z0-9()@:%_\+.~#?&//=]*)"
        matches = re.findall(url_pattern, content)
        
        if matches:
            print("📝 Found these URLs that could be replaced:")
            for i, url in enumerate(matches):
                print(f"  {i+1}. {url}")
            
            try:
                choice = input("Enter number to replace (or 'all' for all, 'n' to cancel): ")
                if choice.lower() == 'n':
                    return False
                elif choice.lower() == 'all':
                    for url in matches:
                        content = content.replace(url, tunnel_url)
                else:
                    idx = int(choice) - 1
                    if 0 <= idx < len(matches):
                        content = content.replace(matches[idx], tunnel_url)
                    else:
                        print("❌ Invalid choice")
                        return False
            except (ValueError, IndexError):
                print("❌ Invalid input")
                return False
        else:
            print("❌ No URLs found to replace")
            return False
    else:
        content = new_content
    
    # Write the updated content
    api_config_path.write_text(content)
    print(f"✅ Updated API config to use tunnel URL: {tunnel_url}")
    return True

def main():
    """Update the API config with a tunnel URL"""
    print("🔄 API Configuration Updater for Fedha App")
    
    # Get the tunnel URL from command line or prompt
    if len(sys.argv) > 1:
        tunnel_url = sys.argv[1]
    else:
        tunnel_url = input("Enter the tunnel URL (e.g., https://beige-insects-lick.loca.lt): ")
    
    # Strip any trailing slashes
    tunnel_url = tunnel_url.rstrip('/')
    
    # Find the API config file
    api_config_path = find_api_config_file()
    if not api_config_path:
        return 1
    
    # Update the API config
    if update_api_config(api_config_path, tunnel_url):
        print("✅ API configuration updated successfully")
        print("🚀 You can now run your app and it will connect to the backend through the tunnel")
    else:
        print("❌ Failed to update API configuration")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
