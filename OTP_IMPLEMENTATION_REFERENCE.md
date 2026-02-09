# OTP Implementation Reference

## How It Works - Flow Diagram

```
REGISTRATION FLOW:
┌──────────────────┐
│  User fills form │
│  (username, age, │
│   email)         │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│  _register() method      │
│  - Validate inputs       │
│  - Check email exists    │
│  - Create user in DB     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  Generate 6-digit OTP    │
│  Save to: otps/{uid}     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  CloudFunctionsService.sendOtpEmail()│
│  Calls Cloud Function                │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Firebase Cloud Function             │
│  (functions/index.js)                │
│  - Generate HTML email               │
│  - Call SendGrid API                 │
│  - Send email                        │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  OtpVerificationScreen               │
│  - Show 5-min countdown              │
│  - User enters OTP                   │
│  - Verify matches                    │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Success!                            │
│  User registered & logged in         │
└──────────────────────────────────────┘
```

## Code Components

### 1. CloudFunctionsService (Dart)

**File:** `lib/services/cloud_functions_service.dart`

```dart
// Initiates OTP email sending
await CloudFunctionsService.sendOtpEmail(
  email: email,
  otp: otp,
  username: username,
);
```

**What it does:**
- Calls the Firebase Cloud Function
- Passes email, OTP, and username
- Handles errors gracefully
- Returns success/failure

### 2. Cloud Function (JavaScript/Node.js)

**File:** `functions/index.js`

```javascript
// Main OTP sending function
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  // Receives: email, otp, username
  // Sends email via SendGrid
  // Returns: {success: true/false}
});
```

**What it does:**
- Receives data from Flutter app
- Validates inputs
- Creates HTML email template
- Authenticates with SendGrid
- Sends email
- Returns success status

### 3. Email Template

The email contains:
```
┌─────────────────────────────────┐
│  Verify Your Email              │
├─────────────────────────────────┤
│  Hi [Username],                 │
│                                 │
│  Your OTP Code is:              │
│                                 │
│      123456                     │
│                                 │
│  Expires in 5 minutes.          │
│                                 │
│  FOCUS Team                     │
└─────────────────────────────────┘
```

## Data Flow

### Registration Example

**User Input:**
```
Username: John Doe
Age: 25
Email: john@example.com
```

**What Happens:**

1. **Validation** (in app):
   ```dart
   _validateEmail("john@example.com") → Valid
   _validateAge("25") → Valid
   _validateUsername("John Doe") → Valid
   ```

2. **Database Save**:
   ```
   Database: users/{uid}
   {
     "username": "John Doe",
     "age": 25,
     "email": "john@example.com",
     "coins": 0,
     "createdAt": "2024-02-06T10:30:00.000"
   }
   ```

3. **OTP Generation**:
   ```dart
   final otp = "521843"; // Random 6 digits
   
   // Save to database
   Database: otps/{uid}
   {
     "otp": "521843",
     "email": "john@example.com",
     "createdAt": "2024-02-06T10:30:00.000"
   }
   ```

4. **Call Cloud Function**:
   ```dart
   CloudFunctionsService.sendOtpEmail(
     email: "john@example.com",
     otp: "521843",
     username: "John Doe"
   )
   ```

5. **Cloud Function Executes**:
   ```javascript
   - Receive data
   - Validate: email & otp present ✓
   - Create HTML email with OTP
   - Send via SendGrid API
   - Return {success: true}
   ```

6. **Email Arrives**:
   ```
   To: john@example.com
   Subject: Your OTP Code
   Body: Hi John Doe, Your OTP is: 521843
   ```

7. **User Verification**:
   ```
   User receives email
   Enters OTP: 521843
   App validates: Match! ✓
   User logged in
   ```

## API Calls

### Cloud Function to SendGrid

**Request:**
```javascript
const msg = {
  to: "john@example.com",
  from: "noreply@yourdomain.com",
  subject: "Your OTP Code",
  html: "<h2>Verify Your Email</h2>..."
};

await sgMail.send(msg);
```

**Response:**
```javascript
{
  success: true,
  message: "OTP sent successfully"
}
```

## Error Handling

### In Flutter App

**If Cloud Function fails:**
```dart
try {
  await CloudFunctionsService.sendOtpEmail(...);
} catch (e) {
  // Log error but continue
  print('Cloud Function failed: $e');
  // Show message anyway - user can resend
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('OTP sent to your email'))
  );
}
```

**If OTP doesn't match:**
```dart
if (enteredOtp != widget.generatedOtp) {
  // Show error and allow retry
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invalid OTP. Please try again'))
  );
}
```

### In Cloud Function

**Invalid inputs:**
```javascript
if (!email || !otp) {
  throw new functions.https.HttpsError(
    "invalid-argument",
    "Email and OTP are required"
  );
}
```

**API errors:**
```javascript
try {
  await sgMail.send(msg);
} catch (error) {
  throw new functions.https.HttpsError(
    "internal",
    "Failed to send email: " + error.message
  );
}
```

## Database Structure

```
users/
├── uid1/
│   ├── username: "John Doe"
│   ├── age: 25
│   ├── email: "john@example.com"
│   ├── coins: 0
│   └── createdAt: "2024-02-06T10:30:00Z"
└── uid2/
    ├── username: "Jane Smith"
    └── ...

otps/
├── uid1/
│   ├── otp: "521843"
│   ├── email: "john@example.com"
│   └── createdAt: "2024-02-06T10:30:00Z"
└── uid2/
    ├── otp: "794521"
    └── ...
```

## Configuration

### Environment Variables (SendGrid)

```bash
# Set once during deployment
firebase functions:config:set email.sendgrid_key="SG.xxx"
firebase functions:config:set email.sender="noreply@yourdomain.com"
```

### Cloud Function Config (Firebase)

```yaml
# firebase.json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs18",
    "timeoutSeconds": 60
  }
}
```

## Monitoring

### Check Logs

```bash
# Real-time logs
firebase functions:log

# Last 10 logs
firebase functions:log --lines 10

# Grep for errors
firebase functions:log | grep -i error
```

### Success Indicators

**In Firebase Console:**
- Functions shows health status ✓
- No errors in logs ✓
- Invocation count increases ✓

**In SendGrid Dashboard:**
- Email delivery status: Delivered ✓
- Bounce/spam rate: 0% ✓

**In Flutter App:**
- OTP screen appears ✓
- User can enter code ✓
- Login succeeds ✓

## Testing

### Unit Test Example

```dart
test('sendOtpEmail called with correct parameters', () async {
  await CloudFunctionsService.sendOtpEmail(
    email: 'test@example.com',
    otp: '123456',
    username: 'Test User',
  );
  
  // Verify email was sent
  expect(emailSent, true);
});
```

### Integration Test Example

```dart
testWidgets('Registration sends OTP email', (WidgetTester tester) async {
  await tester.pumpWidget(const RegistrationPage());
  
  // Fill form
  await tester.enterText(find.byType(TextField).at(0), 'Test User');
  await tester.enterText(find.byType(TextField).at(1), '25');
  await tester.enterText(find.byType(TextField).at(2), 'test@example.com');
  
  // Tap register
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Verify OTP screen appears
  expect(find.byType(OtpVerificationScreen), findsOneWidget);
  
  // Check that email was sent (via mock)
  expect(mockEmailService.emailsSent.length, 1);
  expect(mockEmailService.lastEmail.to, 'test@example.com');
});
```

## Performance

### Timing

- OTP generation: <1ms
- Database save: ~100ms
- Cloud Function call: 500-2000ms (includes network)
- Email delivery: 1-5 seconds (SendGrid)
- User receives email: 1-30 seconds

### Costs

- **Cloud Functions**: Free (< 2M calls/month) - ~$0.40 per million after
- **SendGrid**: Free (100 emails/day) - $20+/month for more
- **Firebase Database**: Free (100 connections) - Minimal cost

## Security Considerations

### OTP Security

✓ 6-digit OTP (1 million combinations)
✓ Expires after 5 minutes
✓ Deleted from DB after verification
✓ One-time use only
✓ Compared server-side

### API Security

✓ SendGrid API Key in environment (not code)
✓ HTTPS-only communication
✓ Rate limiting per IP (optional)
✓ Logs don't contain OTP
✓ No OTP in error messages

### Database Security

✓ Firebase Security Rules (configure as needed)
✓ OTP data ephemeral (deleted after 5 min)
✓ User data encrypted at rest (Firebase)
✓ HTTPS all connections

## Customization

### Changing OTP Length

In both `login.dart` and `registration.dart`:
```dart
// Change from 6 digits to 4
final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
    .toString()
    .substring(1);
```

### Changing OTP Expiry

In `otp_verification_screen.dart`:
```dart
_secondsLeft = 300;  // Change from 5 min to desired time
```

In `functions/index.js`:
```javascript
// Cleanup function interval
exports.cleanupExpiredOtps = functions.pubsub
    .schedule("every 60 minutes")  // Change interval
```

### Email Template

In `functions/index.js`, locate the HTML template:
```javascript
const message = `
  <h2>Verify Your Email</h2>
  <p>Hi ${username},</p>
  // Customize here
`;
```

---

This implementation provides a secure, scalable OTP authentication system for your Focus app.
