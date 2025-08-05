import requests
import sys
import time

def test_health_endpoint(base_url='http://localhost:8000'):
    """Test the health endpoint at the given base URL."""
    health_url = f"{base_url}/api/health/"
    
    print(f"Testing health endpoint at: {health_url}")
    print("=" * 50)
    
    try:
        print(f"Sending GET request to {health_url}...")
        response = requests.get(health_url, timeout=5)
        
        print(f"Status code: {response.status_code}")
        if response.status_code == 200:
            print("✅ Health endpoint is working properly!")
            print("\nResponse content:")
            print("-" * 50)
            try:
                json_response = response.json()
                for key, value in json_response.items():
                    print(f"{key}: {value}")
            except:
                print(response.text)
            return True
        else:
            print(f"❌ Health endpoint returned status code {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"❌ Connection error! Could not connect to {health_url}")
        print("Make sure your Django server is running with:")
        print("   python manage.py runserver 0.0.0.0:8000")
        return False
    except requests.exceptions.Timeout:
        print(f"❌ Request to {health_url} timed out after 5 seconds")
        return False
    except Exception as e:
        print(f"❌ An error occurred: {str(e)}")
        return False

def main():
    # Test localhost connection
    localhost_working = test_health_endpoint('http://localhost:8000')
    
    if not localhost_working:
        print("\nTroubleshooting steps:")
        print("1. Make sure the Django server is running")
        print("2. Check that the 'api/health/' URL is properly configured in urls.py")
        print("3. Ensure there are no errors in the Django server console")
        return
    
    # If localhost works, test network IP
    print("\n" + "=" * 50)
    print("Testing network IP connection...")
    
    # Get local IP address
    import socket
    local_ip = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        print("❌ Could not determine local IP address")
        return
    
    print(f"Detected local IP: {local_ip}")
    time.sleep(1)  # Small pause before the next test
    
    # Test local IP connection
    network_working = test_health_endpoint(f'http://{local_ip}:8000')
    
    if not network_working:
        print("\nTroubleshooting local network connection:")
        print("1. Check your firewall settings - allow inbound connections on port 8000")
        print("2. Verify ALLOWED_HOSTS in settings.py includes your IP address")
        print(f"   Current IP: {local_ip}")
        print("3. Make sure the Django server is bound to 0.0.0.0:8000, not just 127.0.0.1:8000")
    
if __name__ == "__main__":
    main()
