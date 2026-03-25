#!/bin/bash

set -e

echo "🔧 Setting up .env..."
echo ""

if [ -f ".env" ]; then
    echo "⚠️  .env already exists!"
    read -p "Do you want to overwrite it? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

cp .env.example .env
chmod 600 .env

echo "✅ .env created from .env.example"
echo ""
echo "Edit it before running the app:"
echo "  nano .env"
echo ""
echo "Then run:"
echo "  flutter run"
