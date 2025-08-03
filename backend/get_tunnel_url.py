"""
Utility script to get the current tunnel URL for API configuration
"""

import os
import json
import sys

def get_tunnel_url():
    """Get the current tunnel URL from the config file"""
    config_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tunnel_config.json")
    
    if not os.path.exists(config_path):
        print("⚠️  No tunnel configuration found")
        print("💡 Run 'python setup_tunnel.py' to start a tunnel")
        return None
    
    try:
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

if __name__ == "__main__":
    url = get_tunnel_url()
    if url:
        print(f"Current tunnel URL: {url}")
    else:
        print("No active tunnel URL found")
        sys.exit(1)
