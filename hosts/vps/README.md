# VPS Deployment Plan (Debian + Podman Quadlet)

Since a native NixOS installation is not feasible due to memory constraints on the 1GB VM, we are pivoting to a Debian-based deployment. We will use Podman Quadlets to containerize and manage our services, specifically the `rathole` tunnel server.

## Prerequisites

1. **Install Podman**:

   ```bash
   sudo apt update
   sudo apt install -y podman
   ```

2. **Configure IONOS Cloud Firewall**: Ensure that the necessary TCP ports are open in the IONOS Cloud Panel dashboard.
   - Port `22` (SSH)
   - Port `80` (HTTP)
   - Port `443` (HTTPS)
   - Port `2333` (Rathole Control Channel)

   _(Note: We rely entirely on the IONOS cloud firewall and do not install an OS-level firewall like `ufw` to avoid redundancy and confusing connectivity issues)._

## Deployment Steps

### 1. Create Rathole Configuration

We will use a TOML configuration equivalent to the previous NixOS `services.rathole.settings`.

Create the configuration directory:

```bash
sudo mkdir -p /etc/rathole
```

Create `/etc/rathole/server.toml`:

```toml
[server]
bind_addr = "0.0.0.0:2333"

[server.transport]
type = "noise"

[server.transport.noise]
pattern = "Noise_KK_25519_ChaChaPoly_BLAKE2s"

[server.services.http_passthrough]
bind_addr = "0.0.0.0:80"

[server.services.https_passthrough]
bind_addr = "0.0.0.0:443"
```

### 2. Create the Quadlet Container File

Podman Quadlets integrate containers seamlessly into systemd.

Create the systemd containers directory:

```bash
sudo mkdir -p /etc/containers/systemd
```

Create `/etc/containers/systemd/rathole.container`:

```ini
[Unit]
Description=Rathole Server
After=network-online.target

[Container]
Image=docker.io/rapiz1/rathole:latest
Exec=--server /app/server.toml

# Mount configuration read-only
Volume=/etc/rathole/server.toml:/app/server.toml:ro

# Publish ports to the host
PublishPort=2333:2333/tcp
PublishPort=80:80/tcp
PublishPort=443:443/tcp

# Grant permission to bind to privileged ports (< 1024)
AddCapability=CAP_NET_BIND_SERVICE

[Service]
# Auto-restart on failure
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 3. Start the Service

Generate the systemd service from the Quadlet and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl start rathole.service
sudo systemctl status rathole.service
```
