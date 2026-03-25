#!/bin/bash

# Security Verification Script
# This script checks for common security issues in the codebase

set -e

echo "🔍 Running security verification..."
echo ""

ISSUES_FOUND=0

# Function to check for patterns
check_pattern() {
    local pattern=$1
    local description=$2
    local severity=$3
    
    echo -n "Checking for $description... "
    
    # Exclude certain directories and files
    results=$(grep -r \
        --exclude-dir={.git,build,node_modules,.dart_tool,coverage,.github} \
        --exclude="*.lock" \
        --exclude="*.log" \
        --exclude="SECURITY_*.md" \
        --exclude="security_verify.sh" \
        "$pattern" . 2>/dev/null || true)
    
    if [ -n "$results" ]; then
        echo "❌ FOUND ($severity)"
        echo "$results" | head -5
        if [ $(echo "$results" | wc -l) -gt 5 ]; then
            echo "... and more"
        fi
        echo ""
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo "✅ OK"
    fi
}

echo "═══════════════════════════════════════════════════════════"
echo "  Checking for hardcoded secrets..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check for private keys
check_pattern "BEGIN PRIVATE KEY" "private keys" "CRITICAL"
check_pattern "BEGIN RSA PRIVATE KEY" "RSA private keys" "CRITICAL"

# Check for Stripe keys
check_pattern "sk_live_" "Stripe live secret keys" "CRITICAL"
check_pattern "sk_test_" "Stripe test secret keys" "HIGH"
check_pattern "pk_live_[a-zA-Z0-9]{99}" "Stripe live publishable keys (long)" "MEDIUM"

# Check for AWS credentials
check_pattern "AKIA[0-9A-Z]{16}" "AWS access keys" "CRITICAL"

# Check for generic secrets
check_pattern "api_secret" "API secrets" "HIGH"
check_pattern "client_secret.*:.*[a-zA-Z0-9]{20,}" "client secrets" "HIGH"

# Check for passwords
check_pattern "password.*=.*['\"][^'\"]{8,}" "hardcoded passwords" "HIGH"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Checking for sensitive files in git..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if sensitive files are tracked
check_git_file() {
    local pattern=$1
    local description=$2
    
    echo -n "Checking for $description in git... "
    
    results=$(git ls-files | grep -E "$pattern" || true)
    
    if [ -n "$results" ]; then
        echo "❌ FOUND"
        echo "$results"
        echo ""
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo "✅ OK"
    fi
}

check_git_file "\.env$" ".env files"
check_git_file "google-services\.json$" "google-services.json"
check_git_file "GoogleService-Info\.plist$" "GoogleService-Info.plist"
check_git_file "client_secret.*\.json$" "OAuth client secrets"
check_git_file "\.keystore$|\.jks$" "keystore files"
check_git_file "key\.properties$" "key.properties"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Checking gitignore coverage..."
echo "═══════════════════════════════════════════════════════════"
echo ""

check_gitignore() {
    local pattern=$1
    local description=$2
    
    echo -n "Checking .gitignore has $description... "
    
    if grep -q "$pattern" .gitignore 2>/dev/null; then
        echo "✅ OK"
    else
        echo "❌ MISSING"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
}

check_gitignore "\.env$" ".env"
check_gitignore "google-services\.json" "google-services.json"
check_gitignore "GoogleService-Info\.plist" "GoogleService-Info.plist"
check_gitignore "client_secret" "client_secret files"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Checking configuration files..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if secure config files exist
echo -n "Checking for AppConfig class... "
if [ -f "lib/config/app_config.dart" ]; then
    echo "✅ OK"
else
    echo "❌ MISSING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo -n "Checking for build script... "
if [ -f "scripts/build_secure.sh" ]; then
    echo "✅ OK"
else
    echo "❌ MISSING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo -n "Checking for .env.example... "
if [ -f ".env.example" ]; then
    echo "✅ OK"
else
    echo "❌ MISSING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ No security issues found!"
    echo ""
    echo "Your codebase appears to be following security best practices."
    exit 0
else
    echo "⚠️  Found $ISSUES_FOUND security issue(s)"
    echo ""
    echo "Please review the issues above and take appropriate action."
    echo "See docs/SECURITY_CONFIGURATION.md for guidance."
    exit 1
fi
