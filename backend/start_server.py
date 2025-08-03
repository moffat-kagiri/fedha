#!/usr/bin/env python3
"""
Django Server Startup Script for Fedha Backend
Configures and starts the Django development server for Android emulator access
with optional localtunnel support for external access
"""

import os
import sys
import subprocess
import argparse
import socket
import threading
import json
import time
from pathlib import Path

# Import localtunnel module
try:
    import setup_tunnel
except ImportError:
    setup_tunnel = None

def check_requirements(python_cmd):
    """Check if Django and other requirements are installed"""
    try:
        result = subprocess.run([python_cmd, "-c", "import django; print(django.get_version())"], 
                              capture_output=True, text=True, check=True)
        print(f"✅ Django {result.stdout.strip()} is installed")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Django not found!")
        print("💡 Install requirements: pip install -r requirements.txt")
        return False

def get_local_ip():
    """Get the local IP address for network access"""
    try:
        # Connect to a remote address to determine local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "192.168.x.x"

def update_allowed_hosts(local_ip):
    """Update Django ALLOWED_HOSTS to include current local IP"""
    try:
        settings_file = Path("backend/settings.py")
        if settings_file.exists():
            content = settings_file.read_text()
            
            # Check if IP is already in ALLOWED_HOSTS
            if f"'{local_ip}'" not in content:
                print(f"📝 Adding {local_ip} to ALLOWED_HOSTS...")
                
                # Find ALLOWED_HOSTS and add the IP
                import re
                pattern = r"(ALLOWED_HOSTS\s*=\s*\[)(.*?)(\])"
                
                def replace_hosts(match):
                    start, hosts, end = match.groups()
                    if hosts.strip():
                        return f"{start}{hosts.rstrip()}, '{local_ip}'{end}"
                    else:
                        return f"{start}'{local_ip}'{end}"
                
                new_content = re.sub(pattern, replace_hosts, content, flags=re.DOTALL)
                settings_file.write_text(new_content)
                print(f"✅ Added {local_ip} to ALLOWED_HOSTS")
            else:
                print(f"✅ {local_ip} already in ALLOWED_HOSTS")
    except Exception as e:
        print(f"⚠️  Could not update ALLOWED_HOSTS: {e}")

def run_migrations(python_cmd):
    """Run pending migrations"""
    print("🔄 Checking for pending migrations...")
    try:
        subprocess.run([python_cmd, "manage.py", "migrate"], check=True)
        print("✅ Migrations completed")
    except subprocess.CalledProcessError as e:
        print(f"❌ Migration failed: {e}")
        return False
    return True

def main():
    """Start Django server with proper configuration for mobile app access"""
    
    parser = argparse.ArgumentParser(description='Start Fedha Backend Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', default='8000', help='Port to bind to (default: 8000)')
    parser.add_argument('--skip-migrate', action='store_true', help='Skip running migrations')
    parser.add_argument('--skip-checks', action='store_true', help='Skip requirement checks')
    parser.add_argument('--usb-debug', action='store_true', help='Optimize for USB debugging with physical device')
    parser.add_argument('--tunnel', action='store_true', help='Create a localtunnel for external access')
    
    args = parser.parse_args()
    
    # Get the backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    # Get local IP for physical device access
    local_ip = get_local_ip()
    
    # Update ALLOWED_HOSTS if needed
    update_allowed_hosts(local_ip)
    
    print("🚀 Starting Fedha Backend Server...")
    print("📱 Configured for Mobile App Access")
    print("🌐 Server will be accessible at:")
    print(f"   - Android Emulator: http://10.0.2.2:{args.port}")
    print(f"   - Local Machine: http://127.0.0.1:{args.port}")
    print(f"   - Physical Device (USB): http://{local_ip}:{args.port}")
    print(f"   - Network: http://{args.host}:{args.port}")
    
    # Start localtunnel if requested
    tunnel_thread = None
    if args.tunnel and setup_tunnel:
        print("🚇 Setting up external tunnel access...")
        try:
            tunnel_thread = setup_tunnel.run_tunnel_in_thread(port=int(args.port))
            print("🌍 Tunnel initialized - check above for the public URL")
            print("✅ Use this URL in your app's API configuration")
        except Exception as e:
            print(f"❌ Failed to start tunnel: {e}")
            print("💡 You can start it separately with: python setup_tunnel.py")
    
    print("=" * 60)
    
    if args.usb_debug:
        print("� USB DEBUGGING MODE ENABLED")
        print("📱 Setup Instructions for Physical Device:")
        print("   1. Enable 'Developer Options' on your Android device")
        print("   2. Enable 'USB Debugging' in Developer Options")
        print("   3. Connect your device via USB cable")
        print("   4. Allow USB debugging when prompted on device")
        print("   5. Ensure your device is on the same network")
        print(f"   6. Use this URL in your Flutter app: http://{local_ip}:{args.port}")
        print("   7. Test connection: adb devices (should show your device)")
        print("=" * 60)
    else:
        print("📱 For USB Debugging add --usb-debug flag for detailed setup")
        print("=" * 60)
    
    try:
        # Check for virtual environment (multiple possible names)
        venv_paths = [
            backend_dir / ".venv" / "Scripts" / "python.exe",  # Your current .venv
            backend_dir / ".v" / "Scripts" / "python.exe",    # Alternative .v venv
            backend_dir / "venv" / "Scripts" / "python.exe",  # Common venv
            backend_dir / "env" / "Scripts" / "python.exe",   # Common env
        ]
        
        python_cmd = "python"  # Default fallback
        venv_found = False
        
        for venv_python in venv_paths:
            if venv_python.exists():
                python_cmd = str(venv_python)
                venv_name = venv_python.parent.parent.name
                print(f"✅ Using virtual environment: {venv_name}")
                venv_found = True
                break
        
        if not venv_found:
            print("⚠️  Using system Python (virtual environment not found)")
            print("💡 Consider creating a venv: python -m venv .venv")
        
        # Check requirements if not skipped
        if not args.skip_checks:
            if not check_requirements(python_cmd):
                sys.exit(1)
        
        # Run migrations if not skipped
        if not args.skip_migrate:
            if not run_migrations(python_cmd):
                print("⚠️  Continuing despite migration issues...")
        
        # Start Django server
        cmd = [
            python_cmd, 
            "manage.py", 
            "runserver", 
            f"{args.host}:{args.port}"
        ]
        
        print(f"🔄 Running: {' '.join(cmd)}")
        print("📡 Server starting... (Press Ctrl+C to stop)")
        print("=" * 50)
        
        # Run the server
        subprocess.run(cmd, check=True)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error starting server: {e}")
        print("💡 Try running: pip install -r requirements.txt")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
