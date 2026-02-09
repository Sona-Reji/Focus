# OTP Authentication Setup - Complete Guide

This guide covers all steps needed to set up email OTP authentication with Firebase Cloud Functions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App (Login/Registration)                       │
│  ├─ CloudFunctionsService                              │
│  └─ Calls: sendOtpEmail(), resendOtpEmail()           │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│  Firebase Cloud Functions (Node.js)                      │
│  ├─ sendOtpEmail(email, otp, username)                 │
│  ├─ sendWelcomeEmail(email, username)                  │
│  └─ cleanupExpiredOtps (scheduled)                      │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│  SendGrid API                                            │
│  └─ Sends transactional emails                          │
└──────────────────────────────────────────────────────────┘
```

## Quick Start (5 Minutes)

### 1. Install Flutter Dependencies

```bash
cd Focus
flutter pub get
```

This will download the `cloud_functions` package.

### 2. Set Up SendGrid

1. Go to https://sendgrid.com
2. Create free account
3. Verify your sender email (under Settings > Sender Authentication)
4. Create an API Key (Settings > API Keys)
5. Copy the API key

### 3. Initialize Firebase Functions

```bash
# Navigate to project root
cd Focus

# Initialize functions (if not already done)
firebase init functions

# Select JavaScript when prompted
# Choose NOT to overwrite index.js (we have our own)
```

### 4. Install Node Dependencies

```bash
cd functions
npm install
```

### 5. Configure SendGrid

Create `.env.local` file in functions directory:

```
SENDGRID_API_KEY=SG.your_api_key_here
SENDER_EMAIL=noreply@yourdomain.com
```

### 6. Deploy Cloud Functions

```bash
# From project root
firebase deploy --only functions
```

Wait 1-2 minutes for functions to be live.

### 7. Test in Flutter

Run your app and try:
- Register a new user
- You should receive an OTP email!

## Detailed Setup

### A. SendGrid Account Setup

**Create Account:**
- Visit https://sendgrid.com
- Sign up with email
- Verify email address

**Get API Key:**
1. Go to Settings > API Keys
2. Click "Create API Key"
3. Name it "FOCUS App"
4. Copy the entire key (starts with "SG.")
5. Store safely (you'll need it next)

**Verify Sender Email:**
1. Go to Settings > Sender Authentication
2. Click "Verify a Single Sender"
3. Enter your email (e.g., noreply@yourdomain.com)
4. Click verification link in email

### B. Firebase Functions Setup

**Initialize if needed:**
```bash
firebase init functions
# Select: JavaScript
# When asked about index.js: Choose NOT to overwrite
# Install dependencies: Yes
```

**Copy Cloud Functions Code:**
The files are already created:
- `functions/index.js` - The function code
- `functions/package.json` - Dependencies

**Set Environment Variables:**

```bash
# From functions directory
cd functions

# Set SendGrid API key
firebase functions:config:set email.sendgrid_key="SG.your_key_here"

# Set sender email
firebase functions:config:set email.sender="noreply@yourdomain.com"
```

**Or use .env.local (local development):**

Create `functions/.env.local`:
```
SENDGRID_API_KEY=SG.your_key_here
SENDER_EMAIL=noreply@yourdomain.com
```

### C. Deploy to Firebase

```bash
# From project root (Focus directory)
firebase deploy --only functions

# Monitor logs
firebase functions:log
```

### D. Testing

**Test with Local Emulator:**

```bash
firebase emulators:start --only functions
```

Then use your Flutter app - emails will be sent using the emulator.

**Test in Firebase Console:**
1. Go to Firebase Console > Functions
2. Click `sendOtpEmail` function
3. Click "Testing" tab
4. Enter test data:
```json
{
  "email": "your-test-email@gmail.com",
  "otp": "123456",
  "username": "Test User"
}
```
5. Check your email for the test message

## Troubleshooting

### Problem: "cloud_functions package not found"
**Solution:** Run `flutter pub get` from project root

### Problem: Functions not being called
1. Check that functions are deployed:
   ```bash
   firebase functions:list
   ```
2. Verify email from logs:
   ```bash
   firebase functions:log
   ```

### Problem: Email not received
- Check spam/promotions folder
- Verify sender email is authenticated in SendGrid
- Check SendGrid Activity > Bounces/Invalid emails

### Problem: "SENDGRID_API_KEY undefined"
- Make sure environment variables are set correctly
- Redeploy functions: `firebase deploy --only functions`
- Wait 2 minutes for changes to take effect

### Problem: "dial tcp: lookup sendgrid.com"
- Internet connection issue
- Firewall blocking SendGrid
- Try with public WiFi to test

## Code Structure

```
Focus/
├── lib/
│   ├── services/
│   │   └── cloud_functions_service.dart    # Calls Cloud Functions
│   └── screens/
│       └── auth/
│           ├── login.dart                  # Uses CloudFunctionsService
│           ├── registration.dart           # Uses CloudFunctionsService
│           └── otp_verification_screen.dart # Resend functionality
├── functions/
│   ├── index.js                            # Cloud Functions code
│   ├── package.json                        # Node dependencies
│   ├── .env.example                        # Example env file
│   └── .gitignore                          # Git ignore rules
└── pubspec.yaml                            # Flutter dependencies
```

## Cost Breakdown

**SendGrid:**
- Free tier: 100 emails/day
- Paid: $20-995/month depending on volume

**Firebase Cloud Functions:**
- Free tier: 2 million calls/month
- After free tier: $0.40 per million calls

## Security Best Practices

1. **Never commit API keys** - Keep .env files in .gitignore
2. **Rotate API keys** regularly
3. **Use environment variables** instead of hardcoding
4. **Enable OTP expiry** - Already implemented (5 minutes)
5. **Rate limit OTP requests** - Add this if getting spam
6. **HTTPS only** - Firebase Functions use HTTPS by default

## Next Steps

1. ✅ Set up SendGrid account and get API key
2. ✅ Deploy Cloud Functions to Firebase
3. ✅ Test registration and login flows
4. ✅ (Optional) Customize email templates in `functions/index.js`
5. ✅ Monitor Firebase Logs in console

## Support & Debugging

**Check Logs:**
```bash
firebase functions:log
```

**Redeploy:**
```bash
firebase deploy --only functions
```

**List Deployed Functions:**
```bash
firebase functions:list
```

**Test Function Directly:**
```bash
firebase functions:shell
```

## Alternative Email Services

If SendGrid doesn't work for you:

### Using Resend (Modern Option)
1. Sign up at https://resend.com
2. Install: `npm install resend`
3. Update `index.js` to use Resend SDK

### Using AWS SES
1. Set up AWS account
2. Install: `npm install @aws-sdk/client-ses`
3. Configure IAM credentials

### Using SMTP (Gmail)
1. Enable "Less secure apps" in Gmail
2. Use nodemailer: `npm install nodemailer`

---

**Questions?** Check Firebase Console > Functions > Logs for detailed error messages.
