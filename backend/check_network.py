import socket
import os

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

if __name__ == "__main__":
    print(f"Your current IP address is: {get_ip()}")
    
    # Try to ping the server
    ip = get_ip()
    server_port = 8000
    print(f"\nTrying to check if Django server is accessible at {ip}:{server_port}...")
    
    response = os.system(f"ping -n 1 {ip}")
    print(f"\nPing response: {'Success' if response == 0 else 'Failed'}")
    
    print("\nMake sure your Django server is running with:")
    print("python manage.py runserver 0.0.0.0:8000")
    
    print("\nCheck your firewall settings to ensure port 8000 is allowed")
