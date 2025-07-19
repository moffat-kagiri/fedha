#!/usr/bin/env python3
"""
Fedha Backend Setup Script
Automates the setup process for the Django backend
"""

import os
import sys
import subprocess
from pathlib import Path

def run_command(cmd, description, check=True):
    """Run a command with description"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, check=check, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} completed")
            return True
        else:
            print(f"❌ {description} failed: {result.stderr}")
            return False
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e}")
        return False

def main():
    """Setup the backend environment"""
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    print("🚀 Fedha Backend Setup")
    print("=" * 30)
    
    # Check if virtual environment exists
    venv_paths = [".venv", ".v", "venv", "env"]
    venv_found = None
    
    for venv_name in venv_paths:
        venv_path = backend_dir / venv_name
        if venv_path.exists():
            venv_found = venv_name
            print(f"✅ Found virtual environment: {venv_name}")
            break
    
    if not venv_found:
        print("📦 Creating virtual environment (.venv)...")
        if not run_command("python -m venv .venv", "Virtual environment creation"):
            print("❌ Failed to create virtual environment")
            sys.exit(1)
        venv_found = ".venv"
    
    # Determine activation command
    if os.name == 'nt':  # Windows
        activate_cmd = f"{venv_found}\\Scripts\\activate"
        pip_cmd = f"{venv_found}\\Scripts\\pip"
        python_cmd = f"{venv_found}\\Scripts\\python"
    else:  # Unix/Linux/Mac
        activate_cmd = f"source {venv_found}/bin/activate"
        pip_cmd = f"{venv_found}/bin/pip"
        python_cmd = f"{venv_found}/bin/python"
    
    # Install requirements
    if (backend_dir / "requirements.txt").exists():
        if not run_command(f"{pip_cmd} install -r requirements.txt", "Installing requirements"):
            print("❌ Failed to install requirements")
            sys.exit(1)
    else:
        print("⚠️  requirements.txt not found")
    
    # Run migrations
    if not run_command(f"{python_cmd} manage.py migrate", "Running migrations"):
        print("⚠️  Migrations failed, but continuing...")
    
    # Create superuser (optional)
    print("\n🔧 Setup complete!")
    print("=" * 30)
    print("📋 Next steps:")
    print(f"   1. Activate virtual environment: {activate_cmd}")
    print("   2. Start server: python start_server.py")
    print("   3. Or use manage.py: python manage.py runserver 0.0.0.0:8000")
    print("\n💡 Optional: Create superuser with 'python manage.py createsuperuser'")

if __name__ == "__main__":
    main()
