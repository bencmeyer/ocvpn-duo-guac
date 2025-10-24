# Use a lightweight base image
FROM debian:bullseye-slim

# Install OpenConnect and other necessary tools
RUN apt-get update && apt-get install -y \
    openconnect \
    expect \
    dnsutils \
    iputils-ping \
    iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the connection script into the container
COPY connect-vpn.sh /usr/local/bin/connect-vpn.sh
RUN chmod +x /usr/local/bin/connect-vpn.sh

# Run as root (required for TUN device access)
USER root

# Default command to run the VPN connection script
CMD ["/usr/local/bin/connect-vpn.sh"]