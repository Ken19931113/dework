#!/bin/bash

# Remove all node_modules folders
rm -rf node_modules
rm -rf packages/*/node_modules
rm -rf pnpm-lock.yaml

# Reinstall all dependencies
pnpm install

# Install Python dependencies
cd packages/backend
pip install -r requirements.txt
cd ../..

chmod +x ./ensure-permissions.sh
./ensure-permissions.sh

echo "Compiling contracts..."
pnpm contracts compile

echo "Installation complete!"
