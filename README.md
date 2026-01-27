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
│  ├── Xvfb (:0 display, 1920x1080)              │
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

## Performance Comparison

| Metric | VNC (old) | Selkies (new) |
|--------|-----------|---------------|
| Latency | ~100ms | ~20ms |
| CPU Usage | 30-50% | <5% |
| Quality | Blocky | Crisp |
| Max FPS | 30 | 60 |

## License

MIT
