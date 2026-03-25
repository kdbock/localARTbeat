#!/bin/bash

echo "⚠️  setup_env_local.sh is deprecated. Using .env instead."
echo ""
exec "$(dirname "$0")/setup_env.sh"
