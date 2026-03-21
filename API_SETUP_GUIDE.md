# OpenWeatherMap API Setup Instructions

## Step-by-Step Guide to Get Your API Key

### Step 1: Visit OpenWeatherMap Website
1. Open your web browser
2. Go to: https://openweathermap.org

### Step 2: Create an Account
1. Click on **"Sign In"** at the top right corner
2. Click on **"Create an Account"** 
3. Fill in the registration form:
   - Email address
   - Username
   - Password
4. Agree to the terms and conditions
5. Click **"Create Account"**

### Step 3: Verify Your Email
1. Check your email inbox
2. Open the verification email from OpenWeatherMap
3. Click on the verification link

### Step 4: Get Your API Key
1. After logging in, you'll be redirected to your account page
2. Click on **"API keys"** tab
3. You'll see a default API key already generated
4. Copy this API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

**Note:** The API key might take a few minutes (up to 2 hours) to become active.

### Step 5: Configure the API Key in the App

1. Open the project in your code editor
2. Navigate to: `lib/core/constants/api_constants.dart`
3. Find this line:
   ```dart
   static const String apiKey = 'YOUR_API_KEY';
   ```
4. Replace `YOUR_API_KEY` with your actual API key:
   ```dart
   static const String apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
5. Save the file

### Step 6: Test the API Key

Run this command in terminal to test:
```bash
curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY"
```

Replace `YOUR_API_KEY` with your actual key.

If successful, you'll get weather data in JSON format.

## Free Plan Limitations

The free plan includes:
- ✅ 60 calls per minute
- ✅ 1,000,000 calls per month
- ✅ Current weather data
- ✅ 5-day forecast
- ✅ 16-day forecast (limited)
- ❌ Historical data (paid)
- ❌ Advanced forecasts (paid)

## API Endpoints Used by This App

### 1. Current Weather Data
```
GET https://api.openweathermap.org/data/2.5/weather
Parameters:
- q: city name (e.g., London)
- lat: latitude
- lon: longitude
- appid: your API key
- units: metric (for Celsius)
```

### 2. 5-Day / 3-Hour Forecast
```
GET https://api.openweathermap.org/data/2.5/forecast
Parameters:
- q: city name
- lat: latitude
- lon: longitude
- appid: your API key
- units: metric
```

## Troubleshooting API Issues

### Error: 401 Unauthorized
**Cause**: Invalid or missing API key
**Solution**: 
1. Check if you've copied the correct API key
2. Verify there are no extra spaces
3. Wait a few hours if the key was just generated

### Error: 404 Not Found
**Cause**: Invalid city name or coordinates
**Solution**: 
1. Check the spelling of the city name
2. Try another city
3. Use coordinates instead

### Error: 429 Too Many Requests
**Cause**: Exceeded API rate limits
**Solution**: 
1. Wait for the rate limit to reset (1 minute)
2. The app has caching to prevent this

### Error: Network Error
**Cause**: No internet connection
**Solution**: 
1. Check your internet connection
2. The app will show cached data if available

## API Response Example

### Current Weather:
```json
{
  "coord": {"lon": -0.1257, "lat": 51.5085},
  "weather": [
    {
      "id": 800,
      "main": "Clear",
      "description": "clear sky",
      "icon": "01d"
    }
  ],
  "main": {
    "temp": 15.5,
    "feels_like": 14.8,
    "temp_min": 13.2,
    "temp_max": 17.3,
    "pressure": 1013,
    "humidity": 72
  },
  "wind": {
    "speed": 3.5
  },
  "clouds": {
    "all": 0
  },
  "dt": 1677849600,
  "sys": {
    "sunrise": 1677826800,
    "sunset": 1677867600
  },
  "name": "London"
}
```

## Security Best Practices

### ⚠️ Important Security Notes:

1. **Never commit API key to public repositories**
   - Add `.env` file to `.gitignore`
   - Use environment variables in production

2. **For this practice project**
   - It's okay to hardcode the key for learning
   - Don't share your API key publicly

3. **For production apps**
   - Use backend proxy
   - Store API key on server
   - Implement request signing

## Alternative: Using .env File (Optional)

If you want better security:

1. Install flutter_dotenv:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.0.2
   ```

2. Create `.env` file:
   ```
   WEATHER_API_KEY=your_api_key_here
   ```

3. Add to `.gitignore`:
   ```
   .env
   ```

4. Load in main.dart:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   Future<void> main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   ```

5. Use in api_constants.dart:
   ```dart
   static String get apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
   ```

## Additional Resources

- **API Documentation**: https://openweathermap.org/api
- **Current Weather**: https://openweathermap.org/current
- **5-Day Forecast**: https://openweathermap.org/forecast5
- **API FAQ**: https://openweathermap.org/faq
- **Support**: https://openweathermap.org/support

## Quick Start Checklist

- [ ] Create OpenWeatherMap account
- [ ] Verify email address
- [ ] Copy API key from dashboard
- [ ] Paste API key in `lib/core/constants/api_constants.dart`
- [ ] Save the file
- [ ] Run `flutter pub get`
- [ ] Run the app with `flutter run`
- [ ] Test with a city search

## Need Help?

If you encounter issues:
1. Check that your API key is activated (may take up to 2 hours)
2. Verify there are no typos in the API key
3. Test the API key with curl command
4. Check OpenWeatherMap status page
5. Review the error message in the app

---

**Note**: Keep your API key private and never share it publicly!

