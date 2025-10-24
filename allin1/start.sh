#!/bin/bash

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
DB_EXISTS=$(mysql -u root -se "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='guacamole';" 2>/dev/null)

if [ -z "$DB_EXISTS" ]; then
    echo "  Creating database..."
    mysql -u root << SQLEOF
CREATE DATABASE IF NOT EXISTS guacamole;
CREATE USER IF NOT EXISTS 'guacamole'@'localhost' IDENTIFIED BY 'guacamole';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE ON guacamole.* TO 'guacamole'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

    echo "  Loading schema..."
    # Use Guacamole's official initdb.sh script to generate correct MySQL schema
    /opt/guacamole/bin/initdb.sh --mysql | mysql -u root guacamole

    echo "  Creating admin user..."
    # Generate password hash using Guacamole's hash algorithm (SHA256)
    HASH=$(echo -n "$GUAC_DEFAULT_PASS" | sha256sum | cut -d' ' -f1)
    SALT="E767AFF8D5E0F1D3A9B2C5D7E1F3A5B7"
    
    # Check if user exists first
    USER_EXISTS=$(mysql -u root guacamole -se "SELECT COUNT(*) FROM guacamole_user WHERE user_id = (SELECT entity_id FROM guacamole_entity WHERE name='$GUAC_DEFAULT_USER' AND type='USER');" 2>/dev/null)
    
    if [ -z "$USER_EXISTS" ] || [ "$USER_EXISTS" -eq 0 ]; then
        # Create new user
        mysql -u root guacamole << SQLEOF
INSERT INTO guacamole_entity (name, type) VALUES ('$GUAC_DEFAULT_USER', 'USER');
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, disabled) 
  VALUES ((SELECT entity_id FROM guacamole_entity WHERE name='$GUAC_DEFAULT_USER' AND type='USER'), 
          UNHEX('$HASH'), UNHEX('$SALT'), 0);
SQLEOF
        echo "  ✓ Admin user created"
    else
        # User already exists - update password
        ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='$GUAC_DEFAULT_USER' AND type='USER';" 2>/dev/null)
        mysql -u root guacamole -e "UPDATE guacamole_user SET password_hash=UNHEX('$HASH'), password_salt=UNHEX('$SALT') WHERE entity_id=$ENTITY_ID;" 2>/dev/null
        echo "  ✓ Admin user password updated"
    fi
    
    # Always ensure admin permissions are set - grant ALL system permissions
    echo "  Setting up admin permissions..."
    
    # Get the user entity ID
    ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='$GUAC_DEFAULT_USER' AND type='USER';" 2>/dev/null)
    echo "    Entity ID for $GUAC_DEFAULT_USER: $ENTITY_ID"
    
    if [ -z "$ENTITY_ID" ]; then
        echo "    ERROR: Could not find entity ID for user!"
    else
        mysql -u root guacamole << SQLEOF
DELETE FROM guacamole_system_permission 
  WHERE entity_id = $ENTITY_ID;
INSERT INTO guacamole_system_permission (entity_id, permission) 
  VALUES ($ENTITY_ID, 'ADMINISTER');
SQLEOF
        
        # Verify permissions were set
        PERM_COUNT=$(mysql -u root guacamole -se "SELECT COUNT(*) FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null)
        echo "  ✓ Admin permissions configured ($PERM_COUNT permissions set)"
    fi
else
    echo "  Database already initialized"
fi

# Configure Guacamole MySQL connection
echo "[4/4] Configuring Guacamole..."
mkdir -p /root/.guacamole
cat > /root/.guacamole/guacamole.properties << 'EOF'
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole
mysql-username: guacamole
mysql-password: guacamole
EOF

# Wait for Guacamole to be available
echo "Waiting for Guacamole to become available..."
GUAC_READY=0
for i in {1..120}; do
    if curl -s http://localhost:8080/guacamole/ >/dev/null 2>&1; then
        echo "✓ Guacamole ready"
        GUAC_READY=1
        break
    fi
    [ $((i % 30)) -eq 0 ] && echo "  Still starting... ($i/120s)"
    sleep 1
done

if [ $GUAC_READY -eq 0 ]; then
    echo "✗ Guacamole failed to start after 120 seconds"
    echo "Checking supervisord status..."
    supervisorctl -c /etc/supervisor/supervisord.conf status
fi

echo ""
echo "=== Services Ready ==="
echo "  Guacamole:   http://localhost:8080/guacamole ($GUAC_DEFAULT_USER/$GUAC_DEFAULT_PASS)"
echo "  Dashboard:   http://localhost:9000"
echo "  MariaDB:     localhost:3306 (ready for connections)"
echo ""

# Keep supervisord running - check if it's still alive
if ! ps aux | grep -v grep | grep supervisord >/dev/null 2>&1; then
    echo "ERROR: supervisord has exited. Restarting..."
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

# Keep container running by tailing supervisor's main logfile
tail -f /var/log/supervisor/supervisord.log
