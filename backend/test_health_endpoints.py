#!/usr/bin/env python
"""
Script to verify the health endpoint of the Fedha backend server.
Tests both the local development server and any specified remote URLs.
"""

import argparse
import json
import sys
import requests
from requests.exceptions import RequestException

# Default endpoints to check
DEFAULT_ENDPOINTS = [
    "http://127.0.0.1:8000/api/health/",       # Local
    "http://192.168.100.6:8000/api/health/",   # Local network
    "http://10.0.2.2:8000/api/health/"         # Android emulator
]

def check_endpoint(url, timeout=5):
    """Check a single health endpoint and return the results"""
    print(f"\nChecking health endpoint: {url}")
    print("----------------------------------------")
    
    try:
        response = requests.get(url, timeout=timeout)
        status_code = response.status_code
        
        print(f"Status code: {status_code}")
        
        if status_code == 200:
            try:
                data = response.json()
                print(f"API Status: {data.get('status', 'unknown')}")
                print(f"Version: {data.get('version', 'unknown')}")
                print(f"Environment: {data.get('environment', 'unknown')}")
                print(f"Database: {data.get('database', 'unknown')}")
                print(f"Timestamp: {data.get('timestamp', 'unknown')}")
                return True, data
            except json.JSONDecodeError:
                print("ERROR: Response is not valid JSON")
                print(f"Response content: {response.text[:100]}...")
                return False, None
        else:
            print(f"ERROR: Received non-200 status code: {status_code}")
            print(f"Response content: {response.text[:100]}...")
            return False, None
            
    except RequestException as e:
        print(f"ERROR: Could not connect to endpoint: {e}")
        return False, None


def main():
    parser = argparse.ArgumentParser(description="Check Fedha backend health endpoints")
    parser.add_argument("--urls", nargs="+", help="List of URLs to check")
    parser.add_argument("--timeout", type=int, default=5, help="Request timeout in seconds")
    
    args = parser.parse_args()
    
    # Use provided URLs or default endpoints
    urls_to_check = args.urls if args.urls else DEFAULT_ENDPOINTS
    
    success_count = 0
    total_count = len(urls_to_check)
    
    # Check each endpoint
    for url in urls_to_check:
        success, _ = check_endpoint(url, args.timeout)
        if success:
            success_count += 1
    
    # Print summary
    print("\n========== SUMMARY ==========")
    print(f"Checked {total_count} endpoints")
    print(f"Successful: {success_count}")
    print(f"Failed: {total_count - success_count}")
    
    # Return success if at least one endpoint is healthy
    return 0 if success_count > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
