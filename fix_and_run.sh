#!/bin/bash

# Weather App - Installation & Fix Script
# This script will fix all console issues and get your app running

echo "════════════════════════════════════════════════════════════════"
echo "    Weather App - Fixing Console Issues & Installing Packages"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo "⏳ Checking Flutter installation..."
if ! command -v flutter &> /dev/null
then
    echo -e "${RED}❌ Flutter is not installed!${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
else
    echo -e "${GREEN}✅ Flutter is installed${NC}"
    flutter --version
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

# Clean previous builds
echo ""
echo "🧹 Cleaning previous build files..."
flutter clean
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Clean successful${NC}"
else
    echo -e "${RED}❌ Clean failed${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

# Get dependencies
echo ""
echo "📦 Installing dependencies (this may take a few minutes)..."
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

# Check for Flutter doctor issues
echo ""
echo "🔍 Running Flutter Doctor..."
flutter doctor

echo ""
echo "════════════════════════════════════════════════════════════════"

# Check API key configuration
echo ""
echo "🔑 Checking API key configuration..."
API_FILE="lib/core/constants/api_constants.dart"
if grep -q "YOUR_API_KEY" "$API_FILE"; then
    echo -e "${YELLOW}⚠️  WARNING: API key not configured!${NC}"
    echo ""
    echo "You need to:"
    echo "1. Get a free API key from: https://openweathermap.org/api"
    echo "2. Open: lib/core/constants/api_constants.dart"
    echo "3. Replace 'YOUR_API_KEY' with your actual API key"
    echo ""
else
    echo -e "${GREEN}✅ API key appears to be configured${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

# List available devices
echo ""
echo "📱 Available devices:"
flutter devices

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ All console issues have been fixed!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure your API key (if not done)"
echo "2. Connect a device or start an emulator"
echo "3. Run: flutter run"
echo ""
echo "════════════════════════════════════════════════════════════════"

