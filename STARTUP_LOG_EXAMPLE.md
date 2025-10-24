# Successful Container Startup Log

This document shows a successful startup sequence for the OpenConnect VPN + Guacamole all-in-one container.

## Expected Startup Output

```
=== OpenConnect VPN + Guacamole All-in-One Startup ===
[1/4] Starting supervisor (manages all services)...
[2/4] Waiting for MariaDB...
✓ MySQL ready
[3/4] Setting up Guacamole database...
  Creating database...
  Loading schema...
  Creating admin user...
    Generated hash: f3293a1a94713ed45a8f23d84f41b41c670a7ae6fef7b05a2b0ba47a06061f43
    Using salt: E767AFF8D5E0F1D3A9B2C5D7E1F3A5B7
  ✓ Admin user password updated
    Stored hash in DB: F3293A1A94713ED45A8F23D84F41B41C670A7AE6FEF7B05A2B0BA47A06061F43
  Setting up admin permissions...
    Entity ID for guacadmin: 1
    Deleted old permissions: 
  ✓ Admin permissions configured (1 permissions set: ADMINISTER)
  Restarting Guacamole to apply permissions...
tomcat: ERROR (not running)
tomcat: started
[4/4] Configuring Guacamole...
Starting Guacamole (Tomcat)...
tomcat: ERROR (already started)
Waiting for Guacamole to become available...
✓ Guacamole ready

=== Services Ready ===
  Guacamole:   http://localhost:8080/guacamole (guacadmin/guacadmin)
  Dashboard:   http://localhost:9000
  MariaDB:     localhost:3306 (ready for connections)
```

## Startup Stages Explained

### [1/4] Starting Supervisor
- Supervisor daemon starts and manages all container services:
  - MariaDB (database)
  - Tomcat (Guacamole application server)
  - OpenConnect VPN client
  - Web dashboard

### [2/4] Waiting for MariaDB
- Container waits for MariaDB to be fully initialized
- Once responsive, it proceeds to database setup

### [3/4] Setting Up Guacamole Database
- Creates the `guacamole` database
- Loads Guacamole schema from official initialization script
- Creates default admin user with specified credentials
- Generates secure password hash using SHA-256 with salt
- Configures admin permissions
- Restarts Guacamole/Tomcat to apply changes

### [4/4] Configuring Guacamole
- Starts Tomcat application server
- Waits for Guacamole web interface to respond
- Confirms all services are running

## Services Ready

Once startup completes, three services are available:

| Service | URL | Purpose |
|---------|-----|---------|
| **Guacamole** | http://localhost:8080/guacamole | Remote desktop gateway web UI |
| **Dashboard** | http://localhost:9000 | VPN status & control panel |
| **MariaDB** | localhost:3306 | Database backend |

## Credentials

- **Guacamole Admin**: guacadmin / guacadmin
- **MariaDB Root**: root / (password via environment)
- **Guacamole DB User**: guacamole / guacamole

## Monitoring Startup

To view container startup logs:

```bash
# Follow logs as they appear
docker logs -f ocvpn-guac

# Get last 100 lines
docker logs --tail 100 ocvpn-guac

# Timestamp logs
docker logs --timestamps ocvpn-guac
```

## Troubleshooting Startup Issues

### MariaDB not ready
- Container may need more time - MariaDB initialization can take 20-30 seconds
- Check: `docker logs ocvpn-guac | grep "MySQL ready"`

### Guacamole not starting
- Check port 8080 isn't in use: `lsof -i :8080`
- Verify Tomcat logs: `docker exec ocvpn-guac tail -f /var/log/supervisor/tomcat.err.log`

### Database connection issues
- Verify database was created: `docker exec ocvpn-guac mysql -u root -e "SHOW DATABASES;"`
- Check guacamole schema: `docker exec ocvpn-guac mysql -u guacamole -p guacamole guacamole -e "SHOW TABLES;"`

## Next Steps After Startup

1. Access Guacamole UI at http://localhost:8080/guacamole
2. Log in with guacadmin/guacadmin
3. Add your first VPN connection
4. Configure RDP/SSH/VNC connections through the VPN
5. Monitor dashboard at http://localhost:9000

