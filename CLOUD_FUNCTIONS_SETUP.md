# Firebase Cloud Functions Setup Guide

This guide will help you set up Firebase Cloud Functions to send OTP emails using SendGrid.

## Prerequisites

1. **SendGrid Account** - Free tier provides 100 emails/day
   - Sign up at https://sendgrid.com
   - Verify your sender email
   - Create an API key

2. **Firebase Project** - Already set up
3. **Firebase CLI** - Install with `npm install -g firebase-tools`
4. **Node.js** - Version 18+

## Setup Steps

### Step 1: Install Firebase Functions Locally

```bash
cd Focus
npm install -g firebase-tools
firebase init functions
```

Choose:
- Use JavaScript
- Install dependencies now

### Step 2: Set up Environment Variables

Create `.env.local` file in the `functions` directory:

```
SENDGRID_API_KEY=your-sendgrid-api-key
SENDER_EMAIL=noreply@your-domain.com
```

For development, set these environment variables:

```bash
firebase functions:config:set email.sendgrid_key="your-key"
firebase functions:config:set email.sender="noreply@your-domain.com"
```

### Step 3: Install Dependencies

```bash
cd functions
npm install
```

The package.json already includes:
- firebase-admin
- firebase-functions
- @sendgrid/mail

### Step 4: Update Firebase Configuration

Edit `functions/index.js` and replace:
- `SENDGRID_API_KEY` with your actual key from environment variables
- `SENDER_EMAIL` with your verified SendGrid sender email

### Step 5: Deploy Cloud Functions

**Deploy to Firebase:**

```bash
firebase deploy --only functions
```

**Or use emulator for testing:**

```bash
firebase emulators:start --only functions
```

## SendGrid Setup

### Quick Start:

1. Go to https://sendgrid.com
2. Click "Sign In" or create account
3. In Settings > API Keys, create new key (Full Access)
4. Copy the API key
5. In Settings > Sender Authentication, verify sender email

### Email Template Customization

Edit the HTML templates in `functions/index.js` to match your brand:

- Change colors from `#4A9B8E` to your brand color
- Update the app URL link
- Add your logo/branding

## Testing

### Test OTP Sending Locally:

```bash
firebase emulators:start --only functions
```

Then call the function from your Flutter app - it will use the emulator.

### Test in Console:

1. Go to Firebase Console
2. Navigate to Functions
3. Click on `sendOtpEmail`
4. Click "Testing" tab
5. Trigger the function with test data:

```json
{
  "email": "test@example.com",
  "otp": "123456",
  "username": "Test User"
}
```

## Troubleshooting

### "sendOtpEmail is not a function"

- Check that `functions/index.js` exports are correct
- Redeploy with `firebase deploy --only functions`
- Wait 1-2 minutes for functions to be live

### SendGrid emails not sending

- Verify API key is correct and has full access
- Verify sender email is authenticated in SendGrid
- Check Firebase Functions logs: `firebase functions:log`

### "SENDGRID_API_KEY undefined"

- Set environment variables:
  ```bash
  firebase functions:config:set email.sendgrid_key="your-key"
  ```
- Or pass as environment variable when deploying

## Production Considerations

1. **Rate Limiting** - Add protection against OTP spam
2. **Cleanup** - The scheduled function `cleanupExpiredOtps` runs hourly to remove old OTPs
3. **Security** - Never expose API keys in code; use Firebase environment variables
4. **Cost** - SendGrid free tier: 100 emails/day, Paid tiers available
5. **Logging** - Check Firebase Console > Functions > Logs for debugging

## Alternative Email Services

If SendGrid doesn't work for you:

### Using Gmail (SMTP):
```bash
npm install nodemailer
```

### Using Resend (Recommended for transactional):
```bash
npm install resend
```

### Using AWS SES:
```bash
npm install@aws-sdk/client-ses
```

## Next Steps

After Cloud Functions are deployed:

1. In your Flutter app, the OTP emails will be sent automatically
2. Users will receive OTPs via email at their registered address
3. Test with a real email address to verify everything works

## Support

For issues:
- Check Firebase Console > Functions > Logs
- Review SendGrid's Delivery Status in their dashboard
- Check spam/promotions folder for test emails
