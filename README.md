# clawdbot-desktop

GPU-accelerated remote desktop for Clawdbot, using Selkies-GStreamer WebRTC streaming with NVENC encoding.

## Features

- **GPU-Accelerated Streaming** - Uses NVIDIA NVENC for ~20ms latency
- **WebRTC Protocol** - Modern, low-latency streaming in any browser
- **Pretty XFCE Desktop** - WhiteSur macOS-style theme + Plank dock
- **Clawdbot Gateway** - Installed and running as a daemon
- **Audio Support** - PulseAudio streaming included

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Coolify (Deployment & Reverse Proxy)           │
├─────────────────────────────────────────────────┤
│  Docker Container (clawdbot-desktop-worker)     │
│                                                 │
│  Supervisord (Process Manager)                  │
│  ├── Xorg (dummy) (:0 display, 1920x1080)        │
│  ├── XFCE4 + Plank (Desktop environment)        │
│  ├── Selkies-GStreamer (WebRTC + NVENC)        │
│  │   └── Port 8080 (HTTPS)                     │
│  └── Clawdbot Daemon                           │
│      └── Port 18789 (WebSocket)                │
│                                                 │
│  Volumes:                                       │
│  ├── /clawdbot_home (config & state)           │
│  └── /workspace (workspace data)               │
└─────────────────────────────────────────────────┘
```

## Quick Start

### Production (with GPU)

```bash
docker compose up -d
```

Access: `https://desktop.yourdomain.com`
- Username: `developer`
- Password: value of `VNC_PASSWORD` (default: `clawdbot`)

### Local Development (without GPU)

```bash
docker compose -f docker-compose.local.yml up -d
```

Access: `http://localhost:8080`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `clawdbot` | Access password (same as before!) |
| `SELKIES_ENCODER` | `nvh264enc` | Video encoder (`nvh264enc` or `x264enc`) |
| `SELKIES_FRAMERATE` | `60` | Target framerate |
| `SELKIES_VIDEO_BITRATE` | `8000` | Bitrate in kbps |
| `SELKIES_P2P_STUN_HOST` | `stun.l.google.com` | STUN server for WebRTC NAT traversal |
| `SELKIES_P2P_STUN_PORT` | `19302` | STUN server port |
| `ANTHROPIC_API_KEY` | - | For Clawdbot |
| `OPENAI_API_KEY` | - | For Clawdbot (optional) |

## Coolify Configuration

After deploying, configure domains in Coolify UI:
- Desktop: your domain → port **8080**
- Gateway: your domain → port **18789**

## GPU Requirements

- NVIDIA GPU with NVENC support (GTX 900+, RTX series)
- NVIDIA Driver 525+ on host
- NVIDIA Container Toolkit

Verify GPU access:
```bash
docker compose exec clawdbot-desktop-worker nvidia-smi
```

## Working with the Environment

### Getting a Shell

To get an interactive root shell inside the running container:
```bash
docker compose exec clawdbot-desktop-worker bash
```

### Managing Services

The container uses `supervisor` to manage all internal processes (Xorg, XFCE, Selkies, etc.). You can manage these services using `supervisorctl`.

- **Check status of all services:**
  ```bash
  supervisorctl status
  ```

- **Restart a specific service (e.g., XFCE):**
  ```bash
  supervisorctl restart xfce4
  ```

### Persistent Desktop Settings

Desktop settings (XFCE panels, Plank dock, autostart apps) persist across container restarts and rebuilds. They're stored in `/clawdbot_home/desktop-config/`.

**Reset to Defaults:**

If you want to reset your desktop customizations back to the original defaults:

```bash
# Reset all desktop settings
docker compose exec clawdbot-desktop-worker rm -rf /clawdbot_home/desktop-config

# Or reset only specific configs
docker compose exec clawdbot-desktop-worker rm -rf /clawdbot_home/desktop-config/xfce4   # XFCE panels/theme
docker compose exec clawdbot-desktop-worker rm -rf /clawdbot_home/desktop-config/plank   # Dock settings
docker compose exec clawdbot-desktop-worker rm -rf /clawdbot_home/desktop-config/autostart  # Startup apps

# Restart to apply defaults
docker compose restart
```

### Key Configuration Files

The container is configured through several files. Understanding these can help with debugging and customization.

- **/etc/supervisor/conf.d/supervisord.conf**: The main `supervisor` configuration file. Defines all the services that are run on container startup.
- **/etc/X11/xorg.conf**: Configures the `Xorg` server and the `dummy` video driver, setting the virtual screen resolution.
- **/usr/local/bin/start-desktop.sh**: This script is executed by `supervisor` to start the XFCE desktop session. It sets environment variables, applies XFCE settings (like enabling compositing), and starts the Plank dock.
- **~/.config/xfce4/**: This directory contains user-specific XFCE4 settings (symlinked to persistent storage).

### Viewing Logs

Logs for each supervised service are located in `/var/log/`.

- **Xorg server log**: `/var/log/xorg.log`
- **Selkies-GStreamer log**: `/var/log/selkies.log`
- **XFCE session log**: `/var/log/xfce4.log`

You can view them live using `tail`:
```bash
tail -f /var/log/selkies.log
```

## Performance Comparison

| Metric | VNC (old) | Selkies (new) |
|--------|-----------|---------------|
| Latency | ~100ms | ~20ms |
| CPU Usage | 30-50% | <5% |
| Quality | Blocky | Crisp |
| Max FPS | 30 | 60 |

## License

MIT
