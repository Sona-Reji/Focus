# OTP Authentication - Quick Start Checklist

## ✅ What's Already Done for You

- [x] CloudFunctionsService created
- [x] Cloud Functions code written (`functions/index.js`)
- [x] Login flow updated to use OTP
- [x] Registration flow updated to use OTP
- [x] OTP verification screen with resend functionality
- [x] All integration code ready

## 📋 What You Need to Do

### Step 1: Create Gmail App Password (2 minutes)
- [ ] Go to https://myaccount.google.com/apppasswords
- [ ] Sign in with your Gmail account
- [ ] Select app: "Mail"
- [ ] Select device: "Windows Computer"
- [ ] Copy the 16-character password shown
- [ ] Note: Keep this password secret!

**Alternative (if apppasswords not available):**
- Enable 2-factor authentication on your Google account first
- Then app passwords will appear in your account settings

### Step 2: Install Flutter Dependencies (1 minute)
```bash
cd Focus
flutter pub get
```
- [ ] Wait for installation to complete

### Step 3: Initialize Firebase Functions (1 minute)
```bash
firebase init functions
```
- [ ] Choose: JavaScript
- [ ] Keep existing index.js: NO (we have ours)
- [ ] Install dependencies: YES

### Step 4: Configure Gmail (1 minute)

**Option A: Using Environment Variables (Recommended)**
```bash
cd functions
firebase functions:config:set email.gmail_user="your-email@gmail.com"
firebase functions:config:set email.gmail_app_password="xxxx xxxx xxxx xxxx"
```

**Option B: Using .env.local**
```bash
# Create functions/.env.local
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

- [ ] Gmail credentials configured

### Step 5: Deploy Functions (2-3 minutes)
```bash
cd Focus  # Back to project root
firebase deploy --only functions
```
- [ ] Wait for "Deploy complete" message
- [ ] Wait 1-2 additional minutes for functions to be live

### Step 6: Test (2 minutes)
```bash
flutter run
```
- [ ] Complete registration with real email
- [ ] Check email for OTP
- [ ] Enter OTP to verify

## 🎯 Expected Behavior

**Registration:**
1. User fills: Username, Age, Email
2. Clicks "Register"
3. App generates 6-digit OTP
4. **Email is sent** with OTP
5. User enters OTP
6. Account created

**Login:**
1. User enters email
2. Clicks "Send OTP"
3. App generates 6-digit OTP
4. **Email is sent** with OTP
5. User enters OTP
6. Logged in

**OTP Verification Screen:**
- 5 minute countdown timer
- Shows time remaining
- Can resend OTP
- Validates 6-digit code

## 🐛 If Something Goes Wrong

### "No email received"
1. Check Gmail account - is the sender email correct?
2. Check spam folder
3. Check Firebase Logs: `firebase functions:log`
4. Verify App Password is correct (no spaces!)

### "GMAIL credentials are incorrect"
- Go to https://myaccount.google.com/apppasswords again
- Make sure you're using the 16-character password
- Copy it without spaces (the environment should handle them)

### "sendOtpEmail is not a function"
```bash
firebase deploy --only functions
# Wait 2 minutes
```

### "GMAIL_USER or GMAIL_APP_PASSWORD is undefined"
- Make sure environment variables are set: `firebase functions:config:get`
- Or use .env.local file in functions directory
- Redeploy: `firebase deploy --only functions`

### "Can't connect to Firebase"
- Check internet connection
- Verify firebase.json exists
- Run: `firebase login`

## 📊 File Structure Added

```
functions/
├── index.js                 ← Cloud Functions code
├── package.json             ← Dependencies
├── .env.example            ← Template for env vars
└── .gitignore              ← Git ignore rules

lib/services/
└── cloud_functions_service.dart  ← Flutter integration

docs/
├── OTP_SETUP_GUIDE.md      ← Full setup instructions
├── CLOUD_FUNCTIONS_SETUP.md ← Detailed guide
└── OTP_QUICK_START.md      ← This file
```

## 🔑 Important Notes

- **Keep App Password Secret** - Never commit to Git
- **5-Minute Expiry** - OTPs expire after 5 minutes
- **Auto Cleanup** - Old OTPs deleted hourly
- **Rate Limits** - Gmail free tier: ~100 emails/day per account
- **Cost** - Free (uses your existing Gmail account)
- **2FA Required** - You need 2-factor authentication on Google for app passwords

## 📞 Need Help?

1. Check Firebase Console > Functions > Logs
2. Enable emulator to test locally
3. Verify SendGrid API key is correct
4. Check spam folder for emails
5. Restart Flutter app

## ✨ Next Steps

After everything is working:
1. Customize email templates in `functions/index.js`
2. Add welcome email on successful registration
3. Add rate limiting to prevent spam
4. Test with multiple users
5. Monitor Firebase Logs in production

---

**Time Estimate:** 10-15 minutes total setup
**Maintenance:** Check Firebase Logs occasionally
