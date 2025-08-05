import socket
import requests
import sys
import os
import subprocess
from urllib.parse import urlparse
import time

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        print(f"Error getting local IP: {e}")
        return "127.0.0.1"

def check_port_in_use(port):
    """Check if a port is already in use"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def test_connection(url, timeout=3):
    """Test connection to a URL"""
    try:
        print(f"Testing connection to: {url}")
        response = requests.get(url, timeout=timeout)
        print(f"  ✅ Connection successful! Status code: {response.status_code}")
        print(f"  Response: {response.text[:200]}..." if len(response.text) > 200 else f"  Response: {response.text}")
        return True
    except requests.exceptions.ConnectionError:
        print(f"  ❌ Connection error! Could not connect to {url}")
        return False
    except requests.exceptions.Timeout:
        print(f"  ❌ Timeout error! Connection to {url} timed out after {timeout} seconds")
        return False
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return False

def check_firewall_for_port(port):
    """Check if firewall is allowing connections on specified port"""
    try:
        result = subprocess.run(
            ['netsh', 'advfirewall', 'firewall', 'show', 'rule', 'name=all', '|', 'findstr', f"LocalPort {port}"],
            capture_output=True,
            text=True,
            shell=True
        )
        if result.stdout.strip():
            print(f"Firewall rules for port {port}:")
            print(result.stdout)
        else:
            print(f"❗ No specific firewall rules found for port {port}.")
            print("You may need to add a firewall rule to allow inbound connections.")
    except Exception as e:
        print(f"Error checking firewall: {e}")

if __name__ == "__main__":
    local_ip = get_local_ip()
    port = 8000  # Django default port
    
    print(f"\n==== NETWORK CONNECTION TEST ====")
    print(f"Local IP address: {local_ip}")
    
    # Test if port is in use
    if check_port_in_use(port):
        print(f"✅ Port {port} is in use - a server appears to be running")
    else:
        print(f"❌ Port {port} is not in use. Django server may not be running!")
        print(f"Start Django server with: python manage.py runserver 0.0.0.0:{port}")
        sys.exit(1)
    
    # Test connections
    print("\n==== TESTING CONNECTIONS ====")
    endpoints = [
        f"http://localhost:{port}/api/health/",
        f"http://127.0.0.1:{port}/api/health/",
        f"http://{local_ip}:{port}/api/health/"
    ]
    
    success_count = 0
    for endpoint in endpoints:
        if test_connection(endpoint):
            success_count += 1
    
    print(f"\nSuccessfully connected to {success_count} out of {len(endpoints)} endpoints")
    
    # Check firewall settings
    print("\n==== FIREWALL CHECK ====")
    check_firewall_for_port(port)
    
    # Additional advice
    print("\n==== RECOMMENDATIONS ====")
    if success_count < len(endpoints):
        print("1. Make sure Django is running with: python manage.py runserver 0.0.0.0:8000")
        print("2. Check if your firewall is blocking connections on port 8000")
        print("3. Try temporarily disabling your firewall to test connectivity")
        print("4. Verify ALLOWED_HOSTS in Django settings includes your IP address")
    else:
        print("All connections working properly! Your server appears to be correctly configured.")
        
    print("\n==== TESTING CLOUDFLARE TUNNEL ====")
    test_connection("https://place-jd-telecom-hi.trycloudflare.com/api/health/")
