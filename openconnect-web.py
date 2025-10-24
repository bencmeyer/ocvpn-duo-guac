#!/usr/bin/env python3
"""
OpenConnect Web UI - Simple web interface to control VPN connection
"""

from flask import Flask, render_template, jsonify, request
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
LOG_FILE = '/var/log/supervisor/openconnect-vpn.log'

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

def get_logs(lines=50):
    """Get recent logs"""
    try:
        with open(LOG_FILE, 'r') as f:
            all_lines = f.readlines()
        return ''.join(all_lines[-lines:])
    except:
        return "Logs not available"

@app.route('/')
def index():
    """Main dashboard"""
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

@app.route('/api/connect', methods=['POST'])
def api_connect():
    """Restart VPN connection"""
    try:
        # Restart the openconnect-vpn service via supervisor
        subprocess.run(['supervisorctl', 'restart', 'openconnect-vpn'], 
                      check=True)
        time.sleep(2)
        return jsonify({'success': True, 'message': 'VPN connection restarting'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/disconnect', methods=['POST'])
def api_disconnect():
    """Stop VPN connection"""
    try:
        subprocess.run(['supervisorctl', 'stop', 'openconnect-vpn'], 
                      check=True)
        return jsonify({'success': True, 'message': 'VPN connection stopped'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/reconnect', methods=['POST'])
def api_reconnect():
    """Reconnect VPN"""
    try:
        subprocess.run(['supervisorctl', 'restart', 'openconnect-vpn'], 
                      check=True)
        time.sleep(1)
        return jsonify({'success': True, 'message': 'VPN reconnecting'})
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
            .container { max-width: 1200px; margin: 0 auto; }
            .dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
            .panel { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
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
            .logs { background: #f8f9fa; padding: 10px; border: 1px solid #dee2e6; border-radius: 4px; font-family: monospace; font-size: 12px; max-height: 300px; overflow-y: auto; }
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
                        <a href="http://localhost:8080/guacamole/" target="_blank">
                            Open Guacamole Dashboard →
                        </a>
                    </p>
                </div>
            </div>

            <!-- Logs Panel -->
            <div class="panel" style="margin-top: 20px;">
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
                fetch('/api/connect', { method: 'POST' })
                    .then(r => r.json())
                    .then(data => {
                        alert(data.message || data.error);
                        setTimeout(updateStatus, 2000);
                    });
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

            // Update status every 5 seconds
            updateStatus();
            refreshLogs();
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
    
    app.run(host='0.0.0.0', port=8443, ssl_context='adhoc')
