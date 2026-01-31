#!/bin/bash
# =============================================================================
# M2 Desktop - Homebrew Installation
# Installs Homebrew (Linuxbrew) for the developer user
# =============================================================================
set -e

export DEBIAN_FRONTEND=noninteractive

echo "=== Installing Homebrew dependencies ==="
apt-get update
apt-get install -y build-essential procps curl file git
rm -rf /var/lib/apt/lists/*

echo "=== Installing Homebrew ==="
# Install as developer user (non-interactive)
su - developer -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Add Homebrew to developer's PATH
echo '' >> /home/developer/.bashrc
echo '# Homebrew' >> /home/developer/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/developer/.bashrc

# Also add to .profile for login shells
echo '' >> /home/developer/.profile
echo '# Homebrew' >> /home/developer/.profile
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/developer/.profile

# Set ownership
chown -R developer:developer /home/developer/.bashrc /home/developer/.profile

echo "=== Homebrew installed ==="
