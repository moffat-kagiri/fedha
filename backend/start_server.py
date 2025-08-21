#!/usr/bin/env python3
"""
Enhanced Django server startup script for Fedha backend.
Supports automatic migrations, checks, and debugging options.
"""
import argparse
import subprocess
import sys
import os
import socket

def find_python():
    # Use the current Python executable
    return sys.executable


def run_command(command, description=None):
    if description:
        print(f"\n=== {description} ===")
    result = subprocess.call(command, shell=False)
    if result != 0:
        print(f"Command '{' '.join(command)}' exited with code {result}.")
        sys.exit(result)


def get_local_ips():
    ips = []
    hostname = socket.gethostname()
    try:
        # Primary IP
        ips.append(socket.gethostbyname(hostname))
    except Exception:
        pass
    # Try all addresses
    for _, _, _, _, sockaddr in socket.getaddrinfo(hostname, None):
        ip = sockaddr[0]
        if ip not in ips:
            ips.append(ip)
    return ips


def main():
    parser = argparse.ArgumentParser(description="Start Django server with enhanced options.")
    parser.add_argument('--usb-debug', action='store_true', help='Show USB debug network IPs before starting server')
    parser.add_argument('--host', default='127.0.0.1', help='Host address to bind (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=8000, help='Port number to bind (default: 8000)')
    parser.add_argument('--skip-migrate', action='store_true', help='Skip database migrations')
    parser.add_argument('--skip-checks', action='store_true', help='Skip Django system checks')
    args = parser.parse_args()

    python_exec = find_python()
    base_dir = os.path.dirname(os.path.realpath(__file__))
    os.chdir(base_dir)

    # USB debug mode: show network interfaces
    if args.usb_debug:
        print("\n=== USB Debug Mode: Available Network IPs ===")
        for ip in get_local_ips():
            print(f"  - {ip}")
        print("===========================================\n")

    # Run Django system checks
    if not args.skip_checks:
        run_command([python_exec, 'manage.py', 'check'], description='Running Django system checks')

    # Apply migrations
    if not args.skip_migrate:
        run_command([python_exec, 'manage.py', 'migrate'], description='Applying database migrations')

    # Start the development server
    address = f"{args.host}:{args.port}"
    print(f"\nStarting Django development server at http://{address}/\n")
    run_command([python_exec, 'manage.py', 'runserver', address], description='Launching Django server')

if __name__ == '__main__':
    main()
