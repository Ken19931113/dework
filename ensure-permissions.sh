#!/bin/bash

# Make shell scripts executable
chmod +x *.sh

# Make scripts in all packages executable
find packages -name "*.sh" -type f -exec chmod +x {} \;

echo "All shell scripts are now executable."
