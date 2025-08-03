"""
Update the Flutter app's API configuration with the tunnel URL
"""

import os
import json
import re
import sys
from pathlib import Path

def get_tunnel_url():
    """Get the tunnel URL from the config file"""
    try:
        current_dir = Path(__file__).parent
        config_path = current_dir / "tunnel_config.json"
        
        if not config_path.exists():
            print("⚠️  No tunnel configuration found")
            print("💡 Run 'python setup_tunnel.py' to start a tunnel")
            return None
        
        with open(config_path, "r") as f:
            config = json.load(f)
            
        tunnel_url = config.get("tunnel_url")
        if tunnel_url:
            # Strip https:// prefix if present
            if tunnel_url.startswith("https://"):
                tunnel_url = tunnel_url[8:]
            return tunnel_url
        else:
            print("⚠️  Tunnel URL not found in config file")
            return None
    except Exception as e:
        print(f"❌ Error reading tunnel config: {e}")
        return None

def update_api_config(tunnel_url):
    """Update the Flutter app's API configuration with the tunnel URL"""
    try:
        # Find the app directory (parent of the backend directory)
        current_dir = Path(__file__).parent
        app_dir = current_dir.parent / "app"
        
        if not app_dir.exists():
            print("❌ App directory not found")
            return False
        
        # Find the API config file
        api_config_file = app_dir / "lib" / "config" / "api_config.dart"
        
        if not api_config_file.exists():
            print("❌ API config file not found")
            return False
        
        # Read the current content
        content = api_config_file.read_text()
        
        # Update the development configuration
        dev_pattern = r"(factory ApiConfig\.development\(\) \{\s*return const ApiConfig\(\s*primaryApiUrl: ')([^']*)('"
        local_pattern = r"(factory ApiConfig\.local\(\) \{\s*return const ApiConfig\(\s*primaryApiUrl: ')([^']*)('"
        
        content = re.sub(dev_pattern, f"\\1{tunnel_url}\\3", content)
        content = re.sub(local_pattern, f"\\1{tunnel_url}\\3", content)
        
        # Write the updated content
        api_config_file.write_text(content)
        
        print(f"✅ Updated API config with tunnel URL: {tunnel_url}")
        print(f"📁 File updated: {api_config_file}")
        return True
    except Exception as e:
        print(f"❌ Error updating API config: {e}")
        return False

if __name__ == "__main__":
    print("🔄 Updating Flutter app API configuration...")
    
    # Get the tunnel URL
    tunnel_url = get_tunnel_url()
    if not tunnel_url:
        sys.exit(1)
    
    # Update the API config
    if update_api_config(tunnel_url):
        print("✅ API configuration updated successfully")
    else:
        print("❌ Failed to update API configuration")
        sys.exit(1)
