#!/bin/bash
set -e

echo "=== OpenConnect VPN + Guacamole All-in-One Startup ==="

# Export Guacamole environment variables
export GUACAMOLE_HOME=${GUACAMOLE_HOME:-/opt/guacamole}
export GUAC_DEFAULT_USER=${GUAC_DEFAULT_USER:-guacadmin}
export GUAC_DEFAULT_PASS=${GUAC_DEFAULT_PASS:-guacadmin}

# Ensure Guacamole directories exist
mkdir -p $GUACAMOLE_HOME
mkdir -p /root/.guacamole

# Start supervisord - this will manage all services (MariaDB, Tomcat, OpenConnect)
echo "[1/4] Starting supervisor (manages all services)..."
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
SUPERVISOR_PID=$!

# Give MariaDB time to initialize
echo "[2/4] Waiting for MariaDB..."
sleep 20

# Check MySQL connectivity
for i in {1..60}; do
    if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
        echo "✓ MySQL ready"
        break
    fi
    sleep 1
done

# Initialize Guacamole database if needed
echo "[3/4] Setting up Guacamole database..."
if ! mysql -u root -e "USE guacamole; SELECT 1" 2>/dev/null; then
    echo "  Creating database..."
    mysql -u root << SQLEOF
CREATE DATABASE IF NOT EXISTS guacamole;
CREATE USER IF NOT EXISTS 'guacamole'@'localhost' IDENTIFIED BY 'guacamole';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE ON guacamole.* TO 'guacamole'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

    echo "  Loading schema..."
    find /opt/guacamole -name "*.sql" -type f 2>/dev/null | sort | while read f; do
        mysql -u root guacamole < "$f" 2>/dev/null || true
    done

    echo "  Creating admin user..."
    # Check if user already exists
    USER_EXISTS=$(mysql -u root guacamole -se "SELECT COUNT(*) FROM guacamole_user WHERE username='$GUAC_DEFAULT_USER';" 2>/dev/null)
    
    if [ -z "$USER_EXISTS" ] || [ "$USER_EXISTS" -eq 0 ]; then
        # Generate password hash using Guacamole's hash algorithm (SHA256)
        HASH=$(echo -n "$GUAC_DEFAULT_PASS" | sha256sum | cut -d' ' -f1)
        SALT="E767AFF8D5E0F1D3A9B2C5D7E1F3A5B7"
        
        mysql -u root guacamole -e "INSERT INTO guacamole_user (username, password_hash, password_salt, disabled) VALUES ('$GUAC_DEFAULT_USER', UNHEX('$HASH'), UNHEX('$SALT'), 0);" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Admin user created"
        else
            echo "  ✗ Failed to create admin user"
        fi
    else
        echo "  ✓ Admin user already exists"
    fi
fi

# Configure Guacamole MySQL connection
echo "[4/4] Configuring Guacamole..."
cat > /root/.guacamole/guacamole.properties << 'EOF'
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole
mysql-username: guacamole
mysql-password: guacamole
EOF

# Wait for Guacamole to be available
echo "Waiting for Guacamole to become available..."
for i in {1..120}; do
    if curl -s http://localhost:8080/guacamole/ >/dev/null 2>&1; then
        echo "✓ Guacamole ready"
        break
    fi
    [ $((i % 30)) -eq 0 ] && echo "  Still starting... ($i/120s)"
    sleep 1
done

echo ""
echo "=== Services Ready ==="
echo "  Guacamole:   http://localhost:8080/guacamole ($GUAC_DEFAULT_USER/$GUAC_DEFAULT_PASS)"
echo "  Dashboard:   http://localhost:9000"
echo "  MariaDB:     localhost:3306 (ready for connections)"
echo ""

# Keep supervisord running as PID 1
wait $SUPERVISOR_PID
