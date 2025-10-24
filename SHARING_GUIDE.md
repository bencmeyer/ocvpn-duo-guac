# Sharing & Deployment Guide

## For Sharing with Others

### What to Share

1. **Docker Image** (`openconnect-vpn.tar`)
   - Pre-built container image
   - No setup needed, just load and run

2. **Unraid Template** (`openconnect-vpn.xml`)
   - Drop-in template for Unraid users
   - Shows all configuration options in web UI

3. **Documentation** (`README.md`)
   - Usage instructions
   - Configuration examples
   - Troubleshooting guide

4. **Optional: Source Files**
   - `Dockerfile` - For users who want to build themselves
   - `connect-vpn.sh` - The connection script
   - This allows customization and transparency

### GitHub/GitLab Setup

Create a public repository:

```bash
git clone https://github.com/yourusername/openconnect-vpn.git
cd openconnect-vpn

# Add files
git add README.md Dockerfile connect-vpn.sh openconnect-vpn.xml .gitignore
git commit -m "Initial commit: OpenConnect VPN container"
git push origin main
```

**Important**: In `.gitignore`, add:
```
openconnect-vpn.tar
vpn-test.tar
*.log
/appdata/
```

### Distribution Options

**Option 1: Docker Hub** (Recommended for wider use)
```bash
# Login
docker login

# Tag and push
docker tag openconnect-vpn:latest yourusername/openconnect-vpn:latest
docker push yourusername/openconnect-vpn:latest

# Users can then pull directly:
# docker pull yourusername/openconnect-vpn:latest
```

**Option 2: GitHub Releases**
- Upload files to GitHub Releases
- Users download and load locally
- Good for organizations with private registries

**Option 3: Unraid Community Apps**
- Submit XML template to Unraid community
- Makes it available in Unraid app store
- Requires GitHub repo and specific format

---

## Security Considerations for Sharing

### Credentials NOT Included
✅ No default passwords in code  
✅ No credentials in Docker image  
✅ Users provide credentials at runtime  
✅ Password field masked in Unraid UI  

### Code Review
Before sharing, audit:
- No hardcoded secrets in scripts
- No logging of sensitive data
- Proper input validation
- OpenSSL/TLS usage

### Recommended Practices
1. **Use environment variables** for all secrets
2. **Mask passwords** in UI (already done in XML)
3. **Document** security considerations
4. **Use signed commits** for GitHub
5. **Keep dependencies** updated

---

## Renaming & Branding

### Change Name to Your Organization

1. **Update Dockerfile:**
   ```dockerfile
   LABEL maintainer="you@example.com"
   LABEL version="1.0"
   LABEL description="OpenConnect VPN Client - Organization Edition"
   ```

2. **Update XML:**
   ```xml
   <Name>org-openconnect-vpn</Name>
   <Repository>openconnect-vpn:latest</Repository>
   <Icon>https://yoursite.com/logo.png</Icon>
   <Support>https://github.com/yourorg/openconnect-vpn</Support>
   ```

3. **Update README:**
   - Add organization header
   - Link to support/docs
   - Mention who maintains it

### Versioning

Tag releases:
```bash
docker build -t openconnect-vpn:1.0 .
docker build -t openconnect-vpn:latest .
```

Use semantic versioning in README:
- `1.0.0` - Initial release
- `1.0.1` - Bug fixes
- `1.1.0` - New features
- `2.0.0` - Breaking changes

---

## Making Available to Others

### For Small Team/Organization

**Option A: Private Docker Registry**
```bash
# Tag for registry
docker tag openconnect-vpn:latest registry.company.com/openconnect-vpn:latest
docker push registry.company.com/openconnect-vpn:latest

# Users use:
docker pull registry.company.com/openconnect-vpn:latest
```

**Option B: Shared File Server**
```bash
# Upload to shared network
scp openconnect-vpn.tar \\fileserver\docker-images\
scp openconnect-vpn.xml \\fileserver\docker-templates\
```

### For Public Distribution

**Option A: Docker Hub** (Easiest)
- Free for public images
- Easy discoverability
- Automatic updates

**Option B: GitHub Container Registry**
- Part of GitHub
- Better for open source
- Private option available

**Option C: Self-hosted Registry**
- Full control
- Requires infrastructure
- Better for enterprise

---

## Example: Publishing to Docker Hub

```bash
# 1. Create account at hub.docker.com
# 2. Create repository: openconnect-vpn

# 3. Build and tag
docker build -t yourusername/openconnect-vpn:1.0 .
docker build -t yourusername/openconnect-vpn:latest .

# 4. Push
docker push yourusername/openconnect-vpn:1.0
docker push yourusername/openconnect-vpn:latest

# 5. Users can now use:
docker pull yourusername/openconnect-vpn:latest
docker run -e VPN_USER=... -e VPN_PASS=... yourusername/openconnect-vpn:latest
```

---

## Maintenance

### Update Process

When you update:

```bash
# Make changes to scripts
vim connect-vpn.sh

# Rebuild
docker build -t openconnect-vpn:1.0.1 .
docker build -t openconnect-vpn:latest .

# Push to registry
docker push yourusername/openconnect-vpn:1.0.1
docker push yourusername/openconnect-vpn:latest

# Update GitHub
git add -A
git commit -m "Update: Fix DNS handling"
git tag v1.0.1
git push origin main --tags
```

### Version File

Create `VERSION` file:
```
1.0.1
```

Reference in scripts:
```bash
VERSION=$(cat /VERSION)
echo "OpenConnect VPN Container v$VERSION"
```

---

## User Documentation

Create a `INSTALLATION.md`:

```markdown
# Installation

## Docker Hub
\`\`\`bash
docker pull yourusername/openconnect-vpn:latest
docker run -e VPN_USER=user -e VPN_PASS=pass yourusername/openconnect-vpn:latest
\`\`\`

## Unraid
1. Download openconnect-vpn.xml
2. Copy to /boot/config/plugins/dockerMan/templates-user/
3. Go to Docker tab → Add Container
4. Select openconnect-vpn template
5. Fill in your VPN details
```

---

## License

Choose appropriate license:
- **MIT** - Permissive, good for libraries
- **Apache 2.0** - Permissive with patent protection
- **GPL** - Copyleft, requires sharing modifications

Add to repository:
```
LICENSE (file)
README.md - Add "## License" section
```

---

## Support Strategy

**For Public Distribution:**
1. GitHub Issues for bug reports
2. Discussions for questions
3. Security: security@example.com
4. Response time: Best effort

**Document this in README:**
```markdown
## Support

- **Issues**: https://github.com/yourorg/openconnect-vpn/issues
- **Discussions**: https://github.com/yourorg/openconnect-vpn/discussions
- **Security**: Email security@yourorg.com
```
