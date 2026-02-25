#!/bin/bash
set -eu

# Set up secrets BEFORE enabling -x - use /tmp to avoid permission issues
SECRETS_DIR="/tmp/issue-scan-secrets"
mkdir -p -m 755 "$SECRETS_DIR/s3-keys"
echo "$GITHUB_TOKEN" > "$SECRETS_DIR/github-token"
chmod 644 "$SECRETS_DIR/github-token"
echo "$S3_KEY_EU" > "$SECRETS_DIR/s3-keys/eu-central-1.linodeobjects.com"
echo "$S3_KEY_US" > "$SECRETS_DIR/s3-keys/us-east-1.linodeobjects.com"
chmod 644 "$SECRETS_DIR/s3-keys"/*
# Parse S3 key (format: "ACCESS SECRET")
read -r S3_ACCESS S3_SECRET <<< "$S3_KEY_LOGS"

set -x

# Verify environment
ls -l /dev/kvm
test -c /dev/kvm
# Check what Testing Farm checked out
git status
git show -s

# Create job-runner config
cat > job-runner.toml << TOML_EOF
[logs]
driver = 's3'

[logs.s3]
url = 'https://cockpit-logs.us-east-1.linodeobjects.com/'
key = {access='$S3_ACCESS', secret='$S3_SECRET'}

[forge.github]
post = true
token = [{file="$SECRETS_DIR/github-token"}]

[container]
run-args = [
    '--device=/dev/kvm',
    '--env=GIT_COMMITTER_NAME=Cockpituous',
    '--env=GIT_COMMITTER_EMAIL=cockpituous@cockpit-project.org',
    '--env=GIT_AUTHOR_NAME=Cockpituous',
    '--env=GIT_AUTHOR_EMAIL=cockpituous@cockpit-project.org',
]

[container.secrets]
github-token = [
    '--volume=$SECRETS_DIR/github-token:/run/secrets/github-token:ro,z,U',
    '--env=COCKPIT_GITHUB_TOKEN_FILE=/run/secrets/github-token',
]
image-upload = [
    '--volume=$SECRETS_DIR/s3-keys:/run/secrets/s3-keys:ro,z,U',
    '--env=COCKPIT_S3_KEY_DIR=/run/secrets/s3-keys',
]
TOML_EOF

BOTS_DIR=$(git rev-parse --show-toplevel)
"$BOTS_DIR/job-runner" --config-file job-runner.toml json "$JOB_JSON"
