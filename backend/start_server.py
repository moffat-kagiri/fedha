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
    parser.add_argument('--host', default='0.0.0.0', help='Host address to bind (default: 0.0.0.0 to allow LAN access)')
    parser.add_argument('--port', type=int, default=8000, help='Port number to bind (default: 8000)')
    parser.add_argument('--skip-migrate', action='store_true', help='Skip database migrations')
    parser.add_argument('--skip-checks', action='store_true', help='Skip Django system checks')
    parser.add_argument('--cf-tunnel', action='store_true', help='Start a Cloudflare Tunnel after launching the server')
    parser.add_argument('--ensure-master-key', action='store_true', help='Ensure a master encryption key exists using bootstrap_master_key')
    parser.add_argument('--create-master-key', action='store_true', help='When used with --ensure-master-key, create a key in the adapter if missing')
    parser.add_argument('--encrypt-existing', action='store_true', help='Run the encrypt_existing_pii command after migrations')
    parser.add_argument('--encrypt-dry-run', action='store_true', help='When used with --encrypt-existing, run in dry-run mode')
    parser.add_argument('--encrypt-limit', type=int, default=0, help='Limit number of records to encrypt (0 = all)')
    parser.add_argument('--encrypt-batch-size', type=int, default=100, help='Batch size for encryption command')
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

    # Ensure master key exists (use with caution in prod)
    if args.ensure_master_key:
        # Safety guard: require ALLOW_AUTO_CREATE_MASTER env var to allow creating a key
        allow_create = os.environ.get('ALLOW_AUTO_CREATE_MASTER', '').lower() in ('1', 'true', 'yes')
        if args.create_master_key and not allow_create:
            print("ERROR: Refusing to auto-create master key. Set ALLOW_AUTO_CREATE_MASTER=yes in the environment to allow this in controlled environments.")
            sys.exit(1)

        cmd = [python_exec, 'manage.py', 'bootstrap_master_key']
        if args.create_master_key:
            cmd.append('--create')
        run_command(cmd, description='Ensuring master encryption key (bootstrap)')

    # Optional: run encrypt_existing_pii to migrate plaintext to encrypted fields
    if args.encrypt_existing:
        enc_cmd = [python_exec, 'manage.py', 'encrypt_existing_pii']
        if args.encrypt_dry_run:
            enc_cmd.append('--dry-run')
        if args.encrypt_limit and args.encrypt_limit > 0:
            enc_cmd += ['--limit', str(args.encrypt_limit)]
        if args.encrypt_batch_size and args.encrypt_batch_size > 0:
            enc_cmd += ['--batch-size', str(args.encrypt_batch_size)]
        run_command(enc_cmd, description='Encrypting existing PII (may be long-running)')

    # Start the development server
    address = f"{args.host}:{args.port}"
    print(f"\nStarting Django development server at http://{address}/\n")
    print("\nPhase summary and next steps:\n  - Phase1: Schema migrations and encrypted fields applied.\n  - Phase2: Key management and rotation utilities available.\n  - Phase3: KMS runtime wired (use --ensure-master-key to bootstrap).\n")
    # Launch server
    run_command([python_exec, 'manage.py', 'runserver', address], description='Launching Django server')
    # Optionally start Cloudflare Tunnel
    if args.cf_tunnel:
        print("\nStarting Cloudflare Tunnel for http://{address}...")
        run_command(['cloudflared', 'tunnel', 'run', '--url', f'http://{address}'], description='Starting Cloudflare Tunnel')

if __name__ == '__main__':
    main()
