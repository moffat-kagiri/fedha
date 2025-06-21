#!/usr/bin/env python3
"""
Django Server Startup Script for Fedha Backend
Configures and starts the Django development server for Android emulator access
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Start Django server with proper configuration for mobile app access"""
    
    # Get the backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    print("🚀 Starting Fedha Backend Server...")
    print("📱 Configured for Android Emulator Access")
    print("🌐 Server will be accessible at:")
    print("   - Android Emulator: http://10.0.2.2:8000")
    print("   - Local Machine: http://127.0.0.1:8000")
    print("   - Network: http://0.0.0.0:8000")
    print("=" * 50)
    
    try:
        # Check if virtual environment exists
        venv_python = backend_dir / "venv" / "Scripts" / "python.exe"
        if venv_python.exists():
            python_cmd = str(venv_python)
            print("✅ Using virtual environment")
        else:
            python_cmd = "python"
            print("⚠️  Using system Python (virtual environment not found)")
        
        # Start Django server
        cmd = [
            python_cmd, 
            "manage.py", 
            "runserver", 
            "0.0.0.0:8000"
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
