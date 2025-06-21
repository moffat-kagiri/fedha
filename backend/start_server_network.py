#!/usr/bin/env python3
"""
Network IP Server Startup Script for Fedha Backend
Automatically detects and uses your computer's IP address for network access
"""

import os
import sys
import subprocess
import socket
from pathlib import Path

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        # Connect to a remote address to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"

def main():
    """Start Django server with network IP for real device access"""
    
    # Get the backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    local_ip = get_local_ip()
    
    print("🚀 Starting Fedha Backend Server (Network Access)...")
    print("📱 Configured for Real Device Access")
    print("🌐 Server will be accessible at:")
    print(f"   - Your Computer's IP: http://{local_ip}:8000")
    print("   - Local Machine: http://127.0.0.1:8000")
    print("   - Network Access: http://0.0.0.0:8000")
    print("=" * 60)
    print(f"📝 Update your Flutter app's api_client.dart to use:")
    print(f"   return \"http://{local_ip}:8000/api\";")
    print("=" * 60)
    
    try:
        # Check if virtual environment exists
        venv_python = backend_dir / "venv" / "Scripts" / "python.exe"
        if venv_python.exists():
            python_cmd = str(venv_python)
            print("✅ Using virtual environment")
        else:
            python_cmd = "python"
            print("⚠️  Using system Python (virtual environment not found)")
        
        # Start Django server on all interfaces
        cmd = [
            python_cmd, 
            "manage.py", 
            "runserver", 
            "0.0.0.0:8000"
        ]
        
        print(f"🔄 Running: {' '.join(cmd)}")
        print("📡 Server starting... (Press Ctrl+C to stop)")
        print("🔥 Make sure your firewall allows port 8000!")
        print("=" * 60)
        
        # Run the server
        subprocess.run(cmd, check=True)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"❌ Server failed to start: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
