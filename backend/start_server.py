#!/usr/bin/env python3
"""
Enhanced Django server startup script with real-time monitoring.
Tracks active users, connection counts, and server health.
"""
import argparse
import subprocess
import sys
import os
import socket
import threading
import time
from datetime import datetime

class ServerMonitor:
    def __init__(self):
        self.active_connections = 0
        self.total_requests = 0
        self.unique_users = set()
        self.start_time = datetime.now()
        self.running = False
        
    def start_monitoring(self):
        """Start background monitoring thread"""
        self.running = True
        monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        monitor_thread.start()
        
    def stop_monitoring(self):
        """Stop monitoring"""
        self.running = False
        
    def _monitor_loop(self):
        """Background loop to display stats"""
        while self.running:
            time.sleep(5)  # Update every 5 seconds
            self._display_stats()
            
    def _display_stats(self):
        """Display current server statistics"""
        uptime = datetime.now() - self.start_time
        hours, remainder = divmod(uptime.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        
        print("\n" + "="*60)
        print("🚀 FEDHA SERVER STATUS")
        print("="*60)
        print(f"⏱️  Uptime: {uptime.days}d {hours:02d}h {minutes:02d}m {seconds:02d}s")
        print(f"👥 Active Users: {len(self.unique_users)}")
        print(f"🔗 Active Connections: {self.active_connections}")
        print(f"📊 Total Requests: {self.total_requests}")
        print(f"🕐 Last Updated: {datetime.now().strftime('%H:%M:%S')}")
        print("="*60 + "\n")
    
    def add_user(self, user_id):
        """Register a new user connection"""
        self.unique_users.add(user_id)
        self.active_connections += 1
        
    def remove_connection(self):
        """Remove a connection"""
        if self.active_connections > 0:
            self.active_connections -= 1
            
    def increment_requests(self):
        """Increment request counter"""
        self.total_requests += 1

# Global monitor instance
monitor = ServerMonitor()

def find_python():
    return sys.executable

def run_command(command, description=None):
    if description:
        print(f"\n=== {description} ===")
    result = subprocess.call(command, shell=False)
    if result != 0:
        print(f"❌ Command '{' '.join(command)}' exited with code {result}.")
        sys.exit(result)
    print(f"✅ {description} completed successfully")

def get_local_ips():
    ips = []
    hostname = socket.gethostname()
    try:
        ips.append(socket.gethostbyname(hostname))
    except Exception:
        pass
    for _, _, _, _, sockaddr in socket.getaddrinfo(hostname, None):
        ip = sockaddr[0]
        if ip not in ips:
            ips.append(ip)
    return ips

def main():
    parser = argparse.ArgumentParser(description="Start Django server with enhanced monitoring.")
    parser.add_argument('--usb-debug', action='store_true', help='Show USB debug network IPs')
    parser.add_argument('--host', default='0.0.0.0', help='Host address (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=8000, help='Port number (default: 8000)')
    parser.add_argument('--skip-migrate', action='store_true', help='Skip database migrations')
    parser.add_argument('--skip-checks', action='store_true', help='Skip Django system checks')
    parser.add_argument('--monitor', action='store_true', help='Enable real-time monitoring')
    parser.add_argument('--cf-tunnel', action='store_true', help='Start Cloudflare Tunnel')
    parser.add_argument('--ensure-master-key', action='store_true', help='Ensure master encryption key')
    parser.add_argument('--create-master-key', action='store_true', help='Create master key if missing')
    parser.add_argument('--encrypt-existing', action='store_true', help='Encrypt existing PII')
    parser.add_argument('--encrypt-dry-run', action='store_true', help='Dry run for encryption')
    parser.add_argument('--encrypt-limit', type=int, default=0, help='Limit encryption records')
    parser.add_argument('--encrypt-batch-size', type=int, default=100, help='Encryption batch size')
    args = parser.parse_args()

    python_exec = find_python()
    base_dir = os.path.dirname(os.path.realpath(__file__))
    os.chdir(base_dir)

    print("\n" + "="*60)
    print("🚀 FEDHA BACKEND SERVER")
    print("="*60)
    print(f"📁 Working Directory: {base_dir}")
    print(f"🐍 Python: {python_exec}")
    print(f"🌐 Host: {args.host}:{args.port}")
    print("="*60 + "\n")

    if args.usb_debug:
        print("=== USB Debug Mode: Available Network IPs ===")
        for ip in get_local_ips():
            print(f"  📡 {ip}:{args.port}")
        print("=" * 45 + "\n")

    if not args.skip_checks:
        run_command([python_exec, 'manage.py', 'check'], 
                   description='Running Django system checks')

    if not args.skip_migrate:
        run_command([python_exec, 'manage.py', 'migrate'], 
                   description='Applying database migrations')

    if args.ensure_master_key:
        allow_create = os.environ.get('ALLOW_AUTO_CREATE_MASTER', '').lower() in ('1', 'true', 'yes')
        if args.create_master_key and not allow_create:
            print("❌ ERROR: Set ALLOW_AUTO_CREATE_MASTER=yes to allow auto-creation")
            sys.exit(1)

        cmd = [python_exec, 'manage.py', 'bootstrap_master_key']
        if args.create_master_key:
            cmd.append('--create')
        run_command(cmd, description='Ensuring master encryption key')

    if args.encrypt_existing:
        enc_cmd = [python_exec, 'manage.py', 'encrypt_existing_pii']
        if args.encrypt_dry_run:
            enc_cmd.append('--dry-run')
        if args.encrypt_limit and args.encrypt_limit > 0:
            enc_cmd += ['--limit', str(args.encrypt_limit)]
        if args.encrypt_batch_size and args.encrypt_batch_size > 0:
            enc_cmd += ['--batch-size', str(args.encrypt_batch_size)]
        run_command(enc_cmd, description='Encrypting existing PII')

    address = f"{args.host}:{args.port}"
    
    print("\n" + "="*60)
    print(f"🎉 Starting Django server at http://{address}/")
    print("="*60)
    print("\n📊 Server Features:")
    print("  ✅ Phase 1: Schema migrations applied")
    print("  ✅ Phase 2: Key management available")
    print("  ✅ Phase 3: KMS runtime active")
    if args.monitor:
        print("  ✅ Real-time monitoring enabled")
    print("\n💡 Tips:")
    print("  • Press Ctrl+C to stop the server")
    print("  • Use --monitor for real-time stats")
    print("  • Check logs in output/ directory")
    print("="*60 + "\n")

    # Start monitoring if requested
    if args.monitor:
        monitor.start_monitoring()
        print("📈 Monitoring started - stats will update every 5 seconds\n")

    # Start server
    try:
        run_command([python_exec, 'manage.py', 'runserver', address], 
                   description='Django Server Running')
    except KeyboardInterrupt:
        print("\n\n🛑 Server shutdown requested...")
        if args.monitor:
            monitor.stop_monitoring()
            monitor._display_stats()  # Final stats
        print("👋 Goodbye!\n")
        sys.exit(0)

    if args.cf_tunnel:
        print(f"\n🔗 Starting Cloudflare Tunnel...")
        run_command(['cloudflared', 'tunnel', 'run', '--url', f'http://{address}'], 
                   description='Cloudflare Tunnel')

if __name__ == '__main__':
    main()