# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`clawdbot-desktop` is a GPU-accelerated Dockerized XFCE4 desktop that runs Clawdbot Gateway and exposes a web-based remote desktop session via Selkies-GStreamer WebRTC streaming. It provides a persistent "AI worker PC" with a full Linux desktop inside a container, remotely accessible from any browser with ~20ms latency using NVENC hardware encoding.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Coolify (Deployment & Reverse Proxy)           │
├─────────────────────────────────────────────────┤
│  Docker Container (clawdbot-desktop-worker)     │
│                                                 │
│  Supervisord (Process Manager)                  │
│  ├── D-Bus (priority 5)                         │
│  ├── PulseAudio (priority 10)                   │
│  ├── Xorg + dummy driver (priority 15)          │
│  ├── XFCE4 + Plank dock (priority 20)           │
│  ├── Selkies-GStreamer (priority 30)            │
│  │   └── Port 8080 (WebRTC)                     │
│  └── Clawdbot Gateway (priority 40)             │
│      └── Port 18789 (WebSocket)                 │
│                                                 │
│  Volumes:                                       │
│  ├── /clawdbot_home (config & state)            │
│  └── /workspace (workspace data)                │
└─────────────────────────────────────────────────┘
```

**Key Components:**
- Base Image: `ghcr.io/selkies-project/selkies-gstreamer/gstreamer:main-ubuntu20.04`
- Streaming: Selkies-GStreamer v1.6.0 with NVENC hardware encoding
- Desktop: XFCE4 with WhiteSur macOS-style theme + Plank dock
- Display: Xorg with dummy driver at 1920x1080
- Process Manager: Supervisord
- AI Agent: Clawdbot Gateway (Node.js 22.x)

## Build and Run

```bash
# Local development (no GPU, software encoding)
docker compose -f docker-compose.local.yml up -d
# Access: http://localhost:8080

# Production (requires NVIDIA Container Toolkit)
docker compose up -d

# Rebuild after changes
docker compose build --no-cache

# Verify GPU access inside container
docker compose exec clawdbot-desktop-worker nvidia-smi

# Get a shell inside the container
docker compose exec clawdbot-desktop-worker bash
```

## Debugging

```bash
# Check service status
supervisorctl status

# View logs
tail -f /var/log/selkies.log    # Selkies-GStreamer
tail -f /var/log/xorg.log       # X server
tail -f /var/log/xfce4.log      # XFCE session
tail -f /var/log/clawdbot.log   # Clawdbot Gateway

# Restart a specific service
supervisorctl restart xfce4
supervisorctl restart selkies
```

## Key Files

| File | Purpose |
|------|---------|
| `scripts/supervisord.conf` | Process definitions and startup order |
| `scripts/entrypoint.sh` | GPU detection, auth setup, starts supervisord |
| `scripts/start-desktop.sh` | XFCE session startup, theme config, Plank launch |
| `config/xorg.conf` | Xorg dummy driver config (1920x1080 resolution) |
| `config/xfce4/` | XFCE panel, theme, and window manager settings |
| `config/plank/` | Plank dock configuration and launcher items |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `clawdbot` | Maps to `SELKIES_BASIC_AUTH_PASSWORD` |
| `SELKIES_ENCODER` | `nvh264enc` | Video encoder (`nvh264enc` for GPU, `x264enc` for CPU) |
| `SELKIES_FRAMERATE` | `60` | Target framerate (30 for CPU encoding) |
| `SELKIES_VIDEO_BITRATE` | `8000` | Bitrate in kbps |

The entrypoint auto-detects GPU and falls back to `x264enc` with 30fps if no NVIDIA GPU is found.

## Coolify Deployment

Configure two domains in Coolify:
- Desktop domain → port **8080** (Selkies WebRTC)
- Gateway domain → port **18789** (Clawdbot API)

WebSocket middleware is configured in `docker-compose.yml` Traefik labels for WebRTC signaling.

## Theme System

WhiteSur theme is installed from git during build with fallbacks:
- GTK Theme: WhiteSur-Dark (fallback: Arc)
- Icons: WhiteSur (fallback: Papirus)
- Cursors: McMojave (fallback: DMZ)
- Wallpaper: Downloaded from WhiteSur-wallpapers repo

Theme settings are applied at runtime in `start-desktop.sh` via `xfconf-query`.
