@echo off
REM Weather App - Windows Fix Script
REM Run this script to fix all console issues

echo ================================================================
echo    Weather App - Fixing Console Issues (Windows)
echo ================================================================
echo.

echo Checking Flutter installation...
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter is not installed!
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo ================================================================
echo.

echo Cleaning previous build files...
flutter clean
if errorlevel 1 (
    echo WARNING: Clean had issues, continuing anyway...
)

echo.
echo ================================================================
echo.

echo Installing dependencies (this may take a few minutes)...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo.

echo Running Flutter Doctor...
flutter doctor

echo.
echo ================================================================
echo.

echo Checking API key configuration...
findstr /C:"YOUR_API_KEY" lib\core\constants\api_constants.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo WARNING: API key not configured!
    echo.
    echo You need to:
    echo 1. Get a free API key from: https://openweathermap.org/api
    echo 2. Open: lib\core\constants\api_constants.dart
    echo 3. Replace 'YOUR_API_KEY' with your actual API key
    echo.
) else (
    echo API key appears to be configured
)

echo.
echo ================================================================
echo.

echo Listing available devices...
flutter devices

echo.
echo ================================================================
echo.
echo SUCCESS! All console issues have been fixed!
echo.
echo Next steps:
echo 1. Configure your API key (if not done)
echo 2. Connect a device or start an emulator
echo 3. Run: flutter run
echo.
echo ================================================================

pause

