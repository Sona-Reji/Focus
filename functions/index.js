const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.database();

// Gmail configuration
const GMAIL_USER = process.env.GMAIL_USER;
const GMAIL_APP_PASSWORD = process.env.GMAIL_APP_PASSWORD;

let transporter = null;

if (GMAIL_USER && GMAIL_APP_PASSWORD) {
  transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: GMAIL_USER,
      pass: GMAIL_APP_PASSWORD,
    },
  });
}

// Cloud Function: Send OTP Email
exports.sendOtpEmail = functions.https.onCall(
    async (data) => {
      const {email, otp, username} = data;

      // Validate input
      if (!email || !otp || !username) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields: email, otp, username",
        );
      }

      if (!transporter) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Email service not configured. " +
            "Set GMAIL_USER and GMAIL_APP_PASSWORD.",
        );
      }

      try {
        const htmlContent = `
        <div style="font-family: Segoe UI; max-width: 500px;">
          <h1 style="color: #4a9b8e;">Focus</h1>
          <p>Hi ${username},</p>
          <p>Your OTP code:</p>
          <div style="background: #f0f4f8; padding: 20px;">
            <p style="font-size: 32px; color: #4a9b8e;">
              ${otp}
            </p>
          </div>
          <p style="color: #e8836b;">Expires in 5 minutes</p>
        </div>`;

        const mailOptions = {
          from: GMAIL_USER,
          to: email,
          subject: "🔐 Your Focus OTP Code",
          html: htmlContent,
        };

        await transporter.sendMail(mailOptions);
        return {success: true};
      } catch (error) {
        console.error("Email error:", error);
        throw new functions.https.HttpsError(
            "internal",
            `Failed to send OTP email: ${error.message}`,
        );
      }
    },
);

// Cloud Function: Send Welcome Email
exports.sendWelcomeEmail = functions.https.onCall(
    async (data) => {
      const {email, username} = data;

      if (!email || !username) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields: email, username",
        );
      }

      if (!transporter) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Email service not configured.",
        );
      }

      try {
        const htmlContent = `
        <div style="font-family: Segoe UI;">
          <h2 style="color: #4a9b8e;">
            Welcome to Focus, ${username}!
          </h2>
          <p>Start achieving your daily goals today.</p>
        </div>`;

        const mailOptions = {
          from: GMAIL_USER,
          to: email,
          subject: "🎉 Welcome to Focus!",
          html: htmlContent,
        };

        await transporter.sendMail(mailOptions);
        return {success: true};
      } catch (error) {
        console.error("Email error:", error);
        throw new functions.https.HttpsError(
            "internal",
            `Failed to send welcome email: ${error.message}`,
        );
      }
    },
);

// Scheduled Cloud Function: Clean up expired OTPs
// Runs hourly to delete OTPs older than 5 minutes
exports.cleanupExpiredOtps = functions.pubsub
    .schedule("every 60 minutes")
    .timeZone("UTC")
    .onRun(async () => {
      const now = Date.now();
      const fiveMinutesAgo = now - (5 * 60 * 1000);

      try {
        const otpsSnapshot = await db.ref("otps").once("value");
        const otps = otpsSnapshot.val();

        if (!otps) return {message: "No OTPs to clean up"};

        const updates = {};
        let deletedCount = 0;

        Object.keys(otps).forEach((key) => {
          if (otps[key].createdAt < fiveMinutesAgo) {
            updates[`/otps/${key}`] = null;
            deletedCount++;
          }
        });

        if (Object.keys(updates).length > 0) {
          await db.ref().update(updates);
        }

        const message = `Cleanup complete. Deleted ${deletedCount} OTPs.`;
        console.log(message);
        return {success: true, deletedCount};
      } catch (error) {
        console.error("Cleanup error:", error);
        throw new functions.https.HttpsError(
            "internal",
            `Failed to cleanup expired OTPs: ${error.message}`,
        );
      }
    });
