# Fedha Backend Server

This directory contains the Django backend server for the Fedha mobile application.

## Quick Start

### Option 1: Enhanced Python Script (Recommended)
```bash
python start_server.py
```

### Option 2: Windows Batch File
```cmd
start.bat
```

### Option 3: PowerShell Script
```powershell
.\start.ps1
```

### Option 4: Traditional Django
```bash
# Activate virtual environment first
.venv\Scripts\Activate  # Windows
source .venv/bin/activate  # Unix/Mac

# Then run
python manage.py runserver 0.0.0.0:8000
```

## Server Configuration

The server is configured to be accessible from:
- **Android Emulator**: `http://10.0.2.2:8000`
- **Local Machine**: `http://127.0.0.1:8000`
- **Physical Device (USB)**: `http://192.168.100.6:8000` (your current IP)
- **Network**: `http://0.0.0.0:8000`

### USB Debugging Setup

For testing on physical Android devices via USB:

1. **Enable Developer Options** on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Developer Options will appear in Settings

2. **Enable USB Debugging**:
   - Go to Settings > Developer Options
   - Enable "USB Debugging"

3. **Connect and Test**:
   ```bash
   # Start server with USB debugging info
   python start_server.py --usb-debug
   
   # Or with custom port
   python start_server.py --usb-debug --port 3000
   ```

4. **Use in Flutter App**:
   - Replace `http://10.0.2.2:8000` with `http://192.168.100.6:8000`
   - The server automatically detects your local IP

## Setup Options

### Automatic Setup
```bash
python setup_backend.py
```
This will:
- Create virtual environment if needed
- Install requirements
- Run migrations
- Provide next steps

### Manual Setup
1. Create virtual environment:
   ```bash
   python -m venv .venv
   ```

2. Activate virtual environment:
   ```bash
   # Windows
   .venv\Scripts\Activate
   
   # Unix/Mac
   source .venv/bin/activate
   ```

3. Install requirements:
   ```bash
   pip install -r requirements.txt
   ```

4. Run migrations:
   ```bash
   python manage.py migrate
   ```

## Advanced Server Options

The enhanced `start_server.py` supports several options:

```bash
# USB debugging mode with setup instructions
python start_server.py --usb-debug

# Custom host and port
python start_server.py --host 192.168.1.100 --port 8080

# Skip migrations (faster startup)
python start_server.py --skip-migrate

# Skip requirement checks
python start_server.py --skip-checks

# Combine options for USB debugging
python start_server.py --usb-debug --port 3000 --skip-migrate
```

## Development Commands

```bash
# Create superuser
python manage.py createsuperuser

# Run tests
python manage.py test

# Check for issues
python manage.py check

# Collect static files
python manage.py collectstatic

# Shell access
python manage.py shell

# Show migrations
python manage.py showmigrations
```

## Virtual Environment Detection

The startup scripts automatically detect and use virtual environments in this order:
1. `.venv` (your current setup)
2. `.v` (alternative naming)
3. `venv` (Django default)
4. `env` (alternative naming)

## Troubleshooting

### Common Issues

1. **Django not found**
   ```bash
   # Activate virtual environment and install requirements
   .venv\Scripts\Activate
   pip install -r requirements.txt
   ```

2. **Migration errors**
   ```bash
   # Reset migrations (development only)
   python manage.py migrate --fake-initial
   ```

3. **Port already in use**
   ```bash
   # Use different port
   python start_server.py --port 8001
   ```

### Environment Variables

Key settings can be configured via environment variables:
- `DJANGO_SETTINGS_MODULE`: Settings module (default: backend.settings)
- `DEBUG`: Debug mode (default: True in development)

## Project Structure

```
backend/
├── backend/           # Django project settings
├── api/              # API application
├── start_server.py   # Enhanced server startup
├── setup_backend.py  # Automated setup
├── start.bat         # Windows batch file
├── start.ps1         # PowerShell script
├── manage.py         # Django management script
├── requirements.txt  # Python dependencies
└── .venv/            # Virtual environment
```

## API Endpoints

The backend provides RESTful API endpoints for the mobile app:
- `/api/` - API root
- Admin interface available at `/admin/` (create superuser first)

## Security Notes

- The current configuration uses `DEBUG=True` and a default secret key
- For production, ensure proper environment variables and security settings
- CORS is configured for mobile app access

## Mobile App Integration

The server is specifically configured for Flutter mobile app development:
- CORS headers enabled for cross-origin requests
- Android emulator accessibility via `10.0.2.2`
- Network binding for real device testing
