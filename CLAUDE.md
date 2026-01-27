# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`clawdbot-desktop` is a GPU-accelerated Dockerized XFCE4 desktop that runs Clawdbot Gateway and exposes a web-based remote desktop session via Selkies-GStreamer WebRTC streaming. It provides a persistent "AI worker PC" with a full Linux XFCE4 desktop inside a container, remotely accessible from any browser with ~20ms latency using NVENC hardware encoding.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Coolify (Deployment & Reverse Proxy)           │
├─────────────────────────────────────────────────┤
│  Docker Container (clawdbot-desktop-worker)     │
│                                                 │
│  Supervisord (Process Manager)                  │
│  ├── D-Bus (system bus)                         │
│  ├── PulseAudio (audio support)                 │
│  ├── Xvfb (:0 display, 1920x1080)              │
│  ├── XFCE4 + Plank (Desktop environment)        │
│  ├── Selkies-GStreamer (WebRTC + NVENC)        │
│  │   └── Port 8080 (WebRTC)                    │
│  └── Clawdbot Gateway                           │
│      └── Port 18789 (WebSocket)                │
│                                                 │
│  Volumes:                                       │
│  ├── /clawdbot_home (config & state)           │
│  └── /workspace (workspace data)               │
│                                                 │
│  GPU Access (NVIDIA NVENC encoding)            │
└─────────────────────────────────────────────────┘
```

**Key Technology Stack:**
- Base Image: `ubuntu:22.04`
- Streaming: Selkies-GStreamer with NVENC hardware encoding (~20ms latency)
- Desktop: XFCE4 with WhiteSur macOS-style theme + Plank dock
- Runtime: Docker + Docker Compose deployed via Coolify
- Process Manager: Supervisord (manages Xvfb, XFCE4, Selkies, Clawdbot)
- AI Agent: Clawdbot Gateway (Node.js 22.x)

## Repository Layout

- `Dockerfile` - Builds XFCE4 + Selkies-GStreamer + Clawdbot image
- `docker-compose.yml` - Production stack for Coolify (GPU, no host ports, volumes)
- `docker-compose.local.yml` - Local development (no GPU, with port mappings)
- `scripts/entrypoint.sh` - Bootstraps supervisord and environment
- `scripts/supervisord.conf` - Defines Xvfb, XFCE4, Selkies, Clawdbot processes
- `scripts/start-desktop.sh` - XFCE4 session startup script
- `config/xfce4/` - XFCE4 configuration files (compositing disabled, WhiteSur theme)
- `config/plank/` - Plank dock configuration (macOS-style dock)
- `config/desktop/` - Desktop shortcut files (Terminal, Workspace)
- `config/autostart/` - Autostart entries for Plank dock
- `config/clawdbot.config.sample.json` - Optional sandbox and workspace defaults
- `docs/prd.md` - Product requirements document

## Build and Run

```bash
# Local development (no GPU, software encoding)
docker compose -f docker-compose.local.yml up -d

# Production (requires NVIDIA Container Toolkit)
docker compose up -d

# Verify GPU access inside container
docker compose exec clawdbot-desktop-worker nvidia-smi
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `clawdbot` | Access password (maps to Selkies basic auth) |
| `SELKIES_ENCODER` | `nvh264enc` | Video encoder (`nvh264enc` or `x264enc`) |
| `SELKIES_FRAMERATE` | `60` | Target framerate |
| `SELKIES_VIDEO_BITRATE` | `8000` | Bitrate in kbps |
| `CLAWDBOT_HOME` | `/clawdbot_home` | Clawdbot data directory |
| `WORKSPACE` | `/workspace` | Workspace directory |
| `ANTHROPIC_API_KEY` | - | Set in Coolify for Clawdbot |
| `OPENAI_API_KEY` | - | Set in Coolify for Clawdbot |

## Exposed Ports (Internal)

- `8080` - Selkies-GStreamer WebRTC interface
- `18789` - Clawdbot UI/API gateway

## Coolify Deployment

1. Connect GitHub repo in Coolify
2. Select Docker Compose build pack
3. Configure environment variables and storage volumes
4. Deploy - Coolify handles HTTPS and reverse proxy routing
5. Configure port routing:
   - Desktop domain → port **8080**
   - Gateway domain → port **18789**

## Supervisord Process Priority

Processes start in this order (lower number = higher priority):
1. `dbus` (priority 5) - D-Bus system daemon
2. `pulseaudio` (priority 10) - Audio support
3. `xvfb` (priority 15) - Virtual framebuffer on :0
4. `xfce4` (priority 20) - XFCE4 desktop session + Plank dock
5. `selkies` (priority 30) - Selkies-GStreamer WebRTC on 8080 (sleeps 5s)
6. `clawdbot-gateway` (priority 40) - Clawdbot Gateway on 18789 (sleeps 10s)

All processes are configured with `autorestart=true`.

## XFCE4 Configuration

XFCE4 is configured for optimal streaming performance:
- Compositing is disabled (critical for streaming performance)
- WhiteSur macOS-style dark theme
- Plank dock at bottom (macOS-style)
- Desktop shortcuts for Terminal and Workspace folder
- Thunar file manager, xfce4-terminal, mousepad text editor included

## Performance

| Metric | VNC (old) | Selkies (new) |
|--------|-----------|---------------|
| Latency | ~100ms | ~20ms |
| CPU Usage | 30-50% | <5% |
| Quality | Blocky | Crisp |
| Max FPS | 30 | 60 |
