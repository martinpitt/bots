#!/bin/bash
set -eu

# Set up secrets FIRST, before enabling -x
mkdir -p ~/.config/cockpit-dev/s3-keys
echo "$GITHUB_TOKEN" > ~/.config/cockpit-dev/github-token
chmod 600 ~/.config/cockpit-dev/github-token
echo "$S3_KEY_EU" > ~/.config/cockpit-dev/s3-keys/eu-central-1.linodeobjects.com
echo "$S3_KEY_US" > ~/.config/cockpit-dev/s3-keys/us-east-1.linodeobjects.com
echo "$S3_KEY_LOGS" > ~/.config/cockpit-dev/s3-keys/cockpit-logs.us-east-1.linodeobjects.com
chmod 600 ~/.config/cockpit-dev/s3-keys/*

set -x

# Configure git
git config --global user.email "cockpituous@cockpit-project.org"
git config --global user.name "Cockpituous"

# Verify environment
ls -l /dev/kvm
test -c /dev/kvm

# Clone the repository
git clone "$GIT_URL" bots
cd bots
git checkout "$GIT_REF"
git log -1 --oneline

# Set GITHUB_BASE so task.py knows which repo to use for API calls
# Strip https://github.com/ prefix and .git suffix
GITHUB_BASE="${GIT_URL#https://github.com/}"
export GITHUB_BASE="${GITHUB_BASE%.git}"

# Run the bot task command - exit status is propagated by set -e
$TASK_COMMAND
