#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
    
    # Add helpful hints for common commands
    if len(sys.argv) > 1:
        command = sys.argv[1]
        if command == 'runserver' and len(sys.argv) == 2:
            print("💡 Tip: Use 'python start_server.py' for enhanced server startup")
            print("   Or specify address: python manage.py runserver 0.0.0.0:8000")
    
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        error_msg = (
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        )
        
        # Provide more specific help
        print(f"❌ {error_msg}")
        print("\n🔧 Quick fixes:")
        print("   1. Activate virtual environment:")
        print("      - Windows: .venv\\Scripts\\Activate")
        print("      - Unix/Mac: source .venv/bin/activate")
        print("   2. Install requirements: pip install -r requirements.txt")
        print("   3. Or use the enhanced startup: python start_server.py")
        
        raise ImportError(error_msg) from exc
        
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
