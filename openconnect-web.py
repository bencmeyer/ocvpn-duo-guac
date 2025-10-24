#!/usr/bin/env python3
"""
OpenConnect Web UI - Simple web interface to control VPN connection
"""

from flask import Flask, render_template, jsonify, request, redirect
import subprocess
import os
import json
import signal
import time
from threading import Thread

app = Flask(__name__)

# Configuration
CONFIG_FILE = '/tmp/openconnect_config.json'
VPN_PID_FILE = '/tmp/openconnect.pid'
LOG_DIR = '/var/log/supervisor'

def get_vpn_status():
    """Check if VPN is connected"""
    try:
        result = subprocess.run(['ip', 'addr', 'show', 'tun0'], 
                              capture_output=True, text=True)
        if result.returncode == 0 and 'inet' in result.stdout:
            # Extract IP
            for line in result.stdout.split('\n'):
                if 'inet' in line and 'tun0' not in line:
                    ip = line.strip().split()[1].split('/')[0]
                    return {
                        'status': 'connected',
                        'ip': ip,
                        'timestamp': time.time()
                    }
        return {'status': 'disconnected'}
    except Exception as e:
        return {'status': 'error', 'error': str(e)}

def get_dns_status():
    """Get current DNS configuration"""
    try:
        with open('/etc/resolv.conf', 'r') as f:
            content = f.read()
        dns_servers = [line.split()[1] for line in content.split('\n') 
                      if line.startswith('nameserver')]
        return dns_servers
    except:
        return []

def get_vpn_settings():
    """Get VPN configuration from environment"""
    return {
        'user': os.environ.get('VPN_USER', 'N/A'),
        'server': os.environ.get('VPN_SERVER', 'vpn.illinois.edu'),
        'authgroup': os.environ.get('VPN_AUTHGROUP', 'OpenConnect1 (Split)'),
        'duo_method': os.environ.get('DUO_METHOD', 'push'),
        'dns_servers': os.environ.get('DNS_SERVERS', '130.126.2.131'),
    }

def get_logs(lines=50):
    """Get recent logs from supervisor output and error logs, formatted nicely"""
    try:
        all_lines = []
        seen_lines = set()
        
        # Read stdout log
        stdout_log = f'{LOG_DIR}/openconnect-vpn.out.log'
        if os.path.exists(stdout_log):
            try:
                with open(stdout_log, 'r') as f:
                    all_lines.extend(f.readlines())
            except:
                pass
        
        # Read stderr log
        stderr_log = f'{LOG_DIR}/openconnect-vpn.err.log'
        if os.path.exists(stderr_log):
            try:
                with open(stderr_log, 'r') as f:
                    all_lines.extend(f.readlines())
            except:
                pass
        
        # Filter and deduplicate
        unique_lines = []
        for line in all_lines[-lines*2:]:  # Get more to filter duplicates
            line = line.rstrip()
            if line and line not in seen_lines and not line.startswith('=================='):
                seen_lines.add(line)
                unique_lines.append(line)
        
        # Return formatted logs (last N unique lines)
        if unique_lines:
            return '\n'.join(unique_lines[-lines:])
        else:
            return "No logs available yet. Start VPN connection to generate logs."
    except Exception as e:
        return f"Error reading logs: {str(e)}"

@app.route('/')
def index():
    """Redirect to dashboard"""
    return redirect('/dashboard')

@app.route('/api/')
def api_index():
    """Main API endpoint - returns status as JSON"""
    status = get_vpn_status()
    dns = get_dns_status()
    return jsonify({
        'status': status['status'],
        'ip': status.get('ip', 'N/A'),
        'dns': dns,
        'timestamp': time.time()
    })

@app.route('/api/status')
def api_status():
    """Get current VPN status"""
    status = get_vpn_status()
    dns = get_dns_status()
    return jsonify({
        'connected': status['status'] == 'connected',
        'ip': status.get('ip', 'N/A'),
        'dns': dns,
        'timestamp': status.get('timestamp', 0)
    })

@app.route('/api/logs')
def api_logs():
    """Get recent logs"""
    lines = request.args.get('lines', 50, type=int)
    return jsonify({'logs': get_logs(lines)})

@app.route('/api/settings')
def api_settings():
    """Get VPN settings"""
    settings = get_vpn_settings()
    return jsonify(settings)

@app.route('/api/connect', methods=['POST'])
def api_connect():
    """Start VPN connection"""
    try:
        # Start the openconnect-vpn service via supervisor
        result = subprocess.run(['supervisorctl', 'start', 'openconnect-vpn'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or f'Exit code: {result.returncode}'
            # Exit code 7 usually means already running, which is okay
            if result.returncode == 7 and 'already' in error_msg.lower():
                return jsonify({'success': True, 'message': 'VPN connection already running'})
            return jsonify({'success': False, 'error': error_msg}), 500
        time.sleep(2)
        return jsonify({'success': True, 'message': 'VPN connection starting'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/disconnect', methods=['POST'])
def api_disconnect():
    """Stop VPN connection"""
    try:
        # Stop the openconnect-vpn service via supervisor
        result = subprocess.run(['supervisorctl', 'stop', 'openconnect-vpn'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or f'Exit code: {result.returncode}'
            return jsonify({'success': False, 'error': error_msg}), 500
        time.sleep(1)
        return jsonify({'success': True, 'message': 'VPN connection stopped'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/reconnect', methods=['POST'])
def api_reconnect():
    """Reconnect VPN"""
    try:
        result = subprocess.run(['supervisorctl', 'restart', 'openconnect-vpn'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or f'Exit code: {result.returncode}'
            return jsonify({'success': False, 'error': error_msg}), 500
        time.sleep(2)
        return jsonify({'success': True, 'message': 'VPN connection restarting'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/dashboard')
def dashboard():
    """Web dashboard (HTML)"""
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>OpenConnect VPN + Guacamole</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .container { max-width: 1400px; margin: 0 auto; }
            .dashboard { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; }
            .panel { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .panel-full { grid-column: 1 / -1; }
            .status { font-size: 18px; font-weight: bold; padding: 10px; border-radius: 4px; margin: 10px 0; }
            .connected { background: #d4edda; color: #155724; }
            .disconnected { background: #f8d7da; color: #721c24; }
            button { padding: 10px 20px; margin: 5px; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; }
            .btn-connect { background: #28a745; color: white; }
            .btn-connect:hover { background: #218838; }
            .btn-disconnect { background: #dc3545; color: white; }
            .btn-disconnect:hover { background: #c82333; }
            .btn-reconnect { background: #007bff; color: white; }
            .btn-reconnect:hover { background: #0056b3; }
            .info { background: #e7f3ff; padding: 10px; margin: 10px 0; border-left: 4px solid #007bff; }
            .logs { background: #f8f9fa; padding: 10px; border: 1px solid #dee2e6; border-radius: 4px; font-family: monospace; font-size: 12px; max-height: 400px; overflow-y: auto; white-space: pre-wrap; word-wrap: break-word; line-height: 1.4; }
            .settings { background: #fff3cd; padding: 10px; margin: 10px 0; border-left: 4px solid #ffc107; font-size: 13px; }
            .setting-row { display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #e0e0e0; }
            .setting-row:last-child { border-bottom: none; }
            .setting-key { font-weight: bold; color: #555; }
            .setting-value { color: #333; word-break: break-all; }
            h2 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
            a { color: #007bff; text-decoration: none; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔒 OpenConnect VPN + Guacamole Dashboard</h1>
            
            <div class="dashboard">
                <!-- VPN Panel -->
                <div class="panel">
                    <h2>VPN Connection</h2>
                    <div id="vpn-status" class="status disconnected">Status: Checking...</div>
                    <div id="vpn-info" class="info"></div>
                    <div>
                        <button class="btn-connect" onclick="connect()">Connect</button>
                        <button class="btn-disconnect" onclick="disconnect()">Disconnect</button>
                        <button class="btn-reconnect" onclick="reconnect()">Reconnect</button>
                    </div>
                </div>

                <!-- Guacamole Panel -->
                <div class="panel">
                    <h2>Guacamole</h2>
                    <div class="info">
                        Guacamole is running on port 8080
                    </div>
                    <p>
                        <a id="guac-link" href="#" target="_blank">
                            Open Guacamole →
                        </a>
                    </p>
                </div>

                <div class="panel">
                    <h2>VPN Settings</h2>
                    <div id="vpn-settings" class="settings">
                        <div class="setting-row">
                            <span class="setting-key">Username:</span>
                            <span class="setting-value" id="setting-user">Loading...</span>
                        </div>
                        <div class="setting-row">
                            <span class="setting-key">Server:</span>
                            <span class="setting-value" id="setting-server">Loading...</span>
                        </div>
                        <div class="setting-row">
                            <span class="setting-key">Auth Group:</span>
                            <span class="setting-value" id="setting-authgroup">Loading...</span>
                        </div>
                        <div class="setting-row">
                            <span class="setting-key">Duo Method:</span>
                            <span class="setting-value" id="setting-duo">Loading...</span>
                        </div>
                        <div class="setting-row">
                            <span class="setting-key">DNS Servers:</span>
                            <span class="setting-value" id="setting-dns">Loading...</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Logs Panel -->
            <div class="panel panel-full" style="margin-top: 20px;">
                <h2>Recent Logs</h2>
                <div id="logs" class="logs">Loading logs...</div>
                <button onclick="refreshLogs()" style="margin-top: 10px;">Refresh Logs</button>
            </div>
        </div>

        <script>
            function updateStatus() {
                fetch('/api/status')
                    .then(r => r.json())
                    .then(data => {
                        const statusEl = document.getElementById('vpn-status');
                        const infoEl = document.getElementById('vpn-info');
                        
                        if (data.connected) {
                            statusEl.textContent = '✅ Status: Connected';
                            statusEl.className = 'status connected';
                            infoEl.innerHTML = `<strong>VPN IP:</strong> ${data.ip}<br><strong>DNS:</strong> ${data.dns.join(', ')}`;
                        } else {
                            statusEl.textContent = '❌ Status: Disconnected';
                            statusEl.className = 'status disconnected';
                            infoEl.innerHTML = 'VPN is not connected';
                        }
                    });
            }

            function connect() {
                const btn = event.target;
                const originalText = btn.textContent;
                btn.textContent = 'Connecting...';
                btn.disabled = true;
                
                fetch('/api/connect', { method: 'POST' })
                    .then(r => r.json())
                    .then(data => {
                        // Don't show alert, just poll for status
                        if (!data.success) {
                            console.error('VPN connection error:', data.error);
                        }
                        // Poll more frequently while connecting
                        pollForConnection(btn, originalText);
                    })
                    .catch(err => {
                        console.error('Connection request failed:', err);
                        btn.textContent = originalText;
                        btn.disabled = false;
                    });
            }
            
            function pollForConnection(btn, originalText) {
                let attempts = 0;
                const maxAttempts = 60; // Try for up to 60 seconds
                
                const pollInterval = setInterval(() => {
                    fetch('/api/status')
                        .then(r => r.json())
                        .then(data => {
                            if (data.connected) {
                                clearInterval(pollInterval);
                                btn.textContent = originalText;
                                btn.disabled = false;
                                updateStatus(); // Update UI immediately
                            } else {
                                attempts++;
                                if (attempts >= maxAttempts) {
                                    clearInterval(pollInterval);
                                    btn.textContent = originalText;
                                    btn.disabled = false;
                                    console.log('Connection timeout - check VPN credentials');
                                }
                            }
                        });
                }, 500); // Check every 500ms
            }

            function disconnect() {
                if (confirm('Stop VPN connection?')) {
                    fetch('/api/disconnect', { method: 'POST' })
                        .then(r => r.json())
                        .then(data => {
                            alert(data.message || data.error);
                            updateStatus();
                        });
                }
            }

            function reconnect() {
                fetch('/api/reconnect', { method: 'POST' })
                    .then(r => r.json())
                    .then(data => {
                        alert(data.message || data.error);
                        setTimeout(updateStatus, 2000);
                    });
            }

            function refreshLogs() {
                fetch('/api/logs?lines=50')
                    .then(r => r.json())
                    .then(data => {
                        document.getElementById('logs').textContent = data.logs;
                    });
            }

            function loadSettings() {
                fetch('/api/settings')
                    .then(r => r.json())
                    .then(data => {
                        document.getElementById('setting-user').textContent = data.user || 'N/A';
                        document.getElementById('setting-server').textContent = data.server || 'N/A';
                        document.getElementById('setting-authgroup').textContent = data.authgroup || 'N/A';
                        document.getElementById('setting-duo').textContent = data.duo_method || 'N/A';
                        document.getElementById('setting-dns').textContent = data.dns_servers || 'N/A';
                    })
                    .catch(err => {
                        console.error('Failed to load settings:', err);
                        document.getElementById('setting-user').textContent = 'Error loading settings';
                    });
            }

            function setGuacamoleLink() {
                // Set Guacamole link to use the current host instead of localhost
                const host = window.location.hostname;
                const guacLink = document.getElementById('guac-link');
                guacLink.href = `http://${host}:8080/guacamole/`;
            }

            // Update status every 5 seconds
            updateStatus();
            refreshLogs();
            loadSettings();
            setGuacamoleLink();
            setInterval(updateStatus, 5000);
        </script>
    </body>
    </html>
    '''

if __name__ == '__main__':
    # Install flask if not present
    try:
        import flask
    except ImportError:
        subprocess.run(['pip3', 'install', 'flask'], check=True)
    
    app.run(host='0.0.0.0', port=9000)
