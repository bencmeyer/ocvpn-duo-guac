#!/usr/bin/env bash

# Disable history expansion to prevent "event not found" errors with special characters like !
set +H

# Enable debugging for troubleshooting
set -x

# Ensure required environment variables are set
if [ -z "$VPN_USER" ] || [ -z "$VPN_PASS" ]; then
  echo "Error: VPN_USER and VPN_PASS environment variables must be set."
  exit 1
fi

# Set defaults for optional parameters
VPN_SERVER="${VPN_SERVER:-vpn.illinois.edu}"
VPN_AUTHGROUP="${VPN_AUTHGROUP:-OpenConnect1 (Split)}"
DUO_METHOD="${DUO_METHOD:-push}"
DEBUG="${DEBUG:-false}"

# Disable debug output if not needed (cleaner logs)
if [ "$DEBUG" != "true" ]; then
  set +x
fi

echo "=========================================="
echo "OpenConnect VPN Client"
echo "=========================================="
echo "Server: $VPN_SERVER"
echo "Auth Group: $VPN_AUTHGROUP"
echo "Duo Method: $DUO_METHOD"
echo "User: $VPN_USER"
echo "=========================================="

# Configure DNS servers if specified
if [ -n "$DNS_SERVERS" ]; then
  echo "Configuring DNS servers: $DNS_SERVERS"
  # Backup original resolv.conf
  cp /etc/resolv.conf /etc/resolv.conf.bak
  # Clear and add new DNS servers
  > /etc/resolv.conf
  for dns in $DNS_SERVERS; do
    echo "nameserver $dns" >> /etc/resolv.conf
  done
fi

# Create an expect script to handle interactive prompts
EXPECT_SCRIPT="/tmp/vpn_expect_script.exp"
cat > "$EXPECT_SCRIPT" <<EXPECT_EOF
#!/usr/bin/expect -f

set timeout -1
set pass "$VPN_PASS"
set user "$VPN_USER"
set server "$VPN_SERVER"
set authgroup "$VPN_AUTHGROUP"
set duo_method "$DUO_METHOD"

spawn openconnect --user \$user --authgroup \$authgroup \$server

# Counter to track which password prompt we're on
set prompt_count 0

expect {
    "Password:" {
        incr prompt_count
        if {\$prompt_count == 1} {
            send -- "\$pass\r"
        } else {
            send -- "\$duo_method\r"
        }
        exp_continue
    }
}

# Wait indefinitely - let openconnect run until it exits
expect eof
EXPECT_EOF

# Make the expect script executable
chmod +x "$EXPECT_SCRIPT"

# Run the expect script with environment variables
# This will keep running as long as openconnect stays connected
"$EXPECT_SCRIPT"