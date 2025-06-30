/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest, onCall} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options including region for South Africa
setGlobalOptions({ 
  maxInstances: 10,
  region: "africa-south1" // South Africa region
});

// CORS configuration for handling requests from the Flutter app
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, ngrok-skip-browser-warning",
};

// Health check endpoint
export const health = onRequest((request, response) => {
  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    response.set(corsHeaders);
    response.status(200).send();
    return;
  }

  response.set(corsHeaders);
  response.json({status: "healthy", timestamp: new Date().toISOString()});
});

// Profile registration endpoint
export const register = onRequest(async (request, response) => {
  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    response.set(corsHeaders);
    response.status(200).send();
    return;
  }

  response.set(corsHeaders);

  if (request.method !== "POST") {
    response.status(405).json({error: "Method not allowed"});
    return;
  }

  try {
    const {name, profileType, pin, email, baseCurrency = "KES", timezone = "GMT+3"} = request.body;

    // Validate required fields
    if (!name || !profileType || !pin) {
      response.status(400).json({error: "Name, profile type, and password are required"});
      return;
    }

    if (pin.length < 6) {
      response.status(400).json({error: "Password must be at least 6 characters"});
      return;
    }

    // Generate unique profile ID
    const profileId = generateProfileId(profileType);
    
    // Hash the password (simple version - in production use bcrypt)
    const passwordHash = await hashPassword(pin);

    // Create profile in Firestore
    const profileData = {
      id: profileId,
      name,
      profileType: profileType === "business" ? "BIZ" : "PERS",
      passwordHash,
      email: email || null,
      baseCurrency,
      timezone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
      isActive: true,
    };

    await admin.firestore().collection("profiles").doc(profileId).set(profileData);

    // Send success response
    response.status(201).json({
      success: true,
      profile_id: profileId,
      user_id: profileId,
      profile_type: profileType,
      name,
      message: "Account created successfully",
    });

  } catch (error) {
    logger.error("Registration error:", error);
    response.status(500).json({error: "Failed to create account"});
  }
});

// Profile login endpoint
export const login = onRequest(async (request, response) => {
  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    response.set(corsHeaders);
    response.status(200).send();
    return;
  }

  response.set(corsHeaders);

  if (request.method !== "POST") {
    response.status(405).json({error: "Method not allowed"});
    return;
  }

  try {
    const {user_id, pin, email} = request.body;

    if ((!user_id && !email) || !pin) {
      response.status(400).json({error: "User ID/email and password are required"});
      return;
    }

    // Find profile in Firestore
    let profileDoc;
    if (user_id) {
      profileDoc = await admin.firestore().collection("profiles").doc(user_id).get();
    } else if (email) {
      const profileQuery = await admin.firestore()
        .collection("profiles")
        .where("email", "==", email)
        .where("isActive", "==", true)
        .limit(1)
        .get();
      
      if (!profileQuery.empty) {
        profileDoc = profileQuery.docs[0];
      }
    }

    if (!profileDoc || !profileDoc.exists) {
      response.status(404).json({error: "Profile not found"});
      return;
    }

    const profile = profileDoc.data();
    if (!profile) {
      response.status(404).json({error: "Profile data not found"});
      return;
    }

    // Verify password
    const isValidPassword = await verifyPassword(pin, profile.passwordHash);
    if (!isValidPassword) {
      response.status(401).json({error: "Invalid password"});
      return;
    }

    // Update last login
    await profileDoc.ref.update({
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send success response
    response.status(200).json({
      success: true,
      profile: {
        id: profile.id,
        user_id: profile.id,
        name: profile.name,
        profile_type: profile.profileType === "BIZ" ? "business" : "personal",
        base_currency: profile.baseCurrency,
        timezone: profile.timezone,
        email: profile.email,
      },
      message: "Login successful",
    });

  } catch (error) {
    logger.error("Login error:", error);
    response.status(500).json({error: "Login failed"});
  }
});

// Password reset endpoint
export const resetPassword = onRequest(async (request, response) => {
  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    response.set(corsHeaders);
    response.status(200).send();
    return;
  }

  response.set(corsHeaders);

  if (request.method !== "POST") {
    response.status(405).json({error: "Method not allowed"});
    return;
  }

  try {
    const {email} = request.body;

    if (!email) {
      response.status(400).json({error: "Email is required"});
      return;
    }

    // Find profile by email
    const profileQuery = await admin.firestore()
      .collection("profiles")
      .where("email", "==", email)
      .where("isActive", "==", true)
      .limit(1)
      .get();

    if (profileQuery.empty) {
      // Don't reveal if email exists for security
      response.status(200).json({
        message: "If an account exists with this email, password reset instructions have been sent.",
      });
      return;
    }

    const profileDoc = profileQuery.docs[0];
    const profile = profileDoc.data();

    // Generate temporary password
    const tempPassword = generateTempPassword();
    const tempPasswordHash = await hashPassword(tempPassword);

    // Update profile with temporary password
    await profileDoc.ref.update({
      passwordHash: tempPasswordHash,
      passwordResetAt: admin.firestore.FieldValue.serverTimestamp(),
      requirePasswordChange: true,
    });

    // Send email with temporary password
    await sendPasswordResetEmail(email, profile.name, tempPassword);

    response.status(200).json({
      message: "If an account exists with this email, password reset instructions have been sent.",
    });

  } catch (error) {
    logger.error("Password reset error:", error);
    response.status(500).json({error: "Failed to process password reset"});
  }
});

// Advanced user registration with email verification (Blaze plan feature)
export const registerWithVerification = onCall(async (request) => {
  const {name, email, password, profileType, baseCurrency = "ZAR"} = request.data;

  try {
    // Create user with Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
      emailVerified: false,
    });

    // Generate verification token
    const verificationLink = await admin.auth().generateEmailVerificationLink(email);

    // Create profile in Firestore
    const profileId = `${profileType.toUpperCase()}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    await admin.firestore().collection('profiles').doc(profileId).set({
      id: profileId,
      name: name,
      email: email,
      profileType: profileType === 'business' ? 'BIZ' : 'PERS',
      baseCurrency: baseCurrency,
      firebaseUid: userRecord.uid,
      emailVerified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    });

    // Send verification email (Blaze plan allows external APIs)
    await sendVerificationEmail(email, name, verificationLink);

    return {
      success: true,
      profileId: profileId,
      message: "Account created successfully. Please check your email for verification.",
      uid: userRecord.uid,
    };
  } catch (error) {
    logger.error("Registration error:", error);
    throw new Error(`Registration failed: ${error}`);
  }
});

// Email notification for new user registration (Firestore trigger)
export const onUserRegistered = onDocumentCreated("profiles/{profileId}", async (event) => {
  const profileData = event.data?.data();
  
  if (profileData && profileData.email) {
    logger.info(`New user registered: ${profileData.email}`);
    
    // Send welcome email with onboarding information
    await sendWelcomeEmail(profileData.email, profileData.name, profileData.id);
    
    // Log analytics event (Blaze plan allows external service calls)
    await logAnalyticsEvent("user_registered", {
      profileId: profileData.id,
      profileType: profileData.profileType,
      baseCurrency: profileData.baseCurrency,
    });
  }
});

// Password reset with custom email template
export const resetPasswordAdvanced = onCall(async (request) => {
  const {email} = request.data;

  try {
    // Generate password reset link
    const resetLink = await admin.auth().generatePasswordResetLink(email);
    
    // Find user profile
    const profileQuery = await admin.firestore()
      .collection('profiles')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!profileQuery.empty) {
      const profile = profileQuery.docs[0].data();
      
      // Send custom password reset email
      await sendPasswordResetEmail(email, profile.name, resetLink);
      
      return {
        success: true,
        message: "Password reset email sent successfully",
      };
    } else {
      throw new Error("User profile not found");
    }
  } catch (error) {
    logger.error("Password reset error:", error);
    throw new Error(`Password reset failed: ${error}`);
  }
});

// Advanced user profile analytics
export const getUserAnalytics = onCall(async (request) => {
  const {profileId} = request.data;

  try {
    // Get profile data
    const profileDoc = await admin.firestore().collection('profiles').doc(profileId).get();
    
    if (!profileDoc.exists) {
      throw new Error("Profile not found");
    }

    const profileData = profileDoc.data();

    // Calculate analytics (Blaze plan allows complex calculations)
    const analytics = {
      profileId: profileId,
      accountAge: calculateAccountAge(profileData?.createdAt),
      lastLoginDays: calculateDaysSinceLastLogin(profileData?.lastLogin),
      profileCompleteness: calculateProfileCompleteness(profileData),
      riskScore: calculateRiskScore(profileData),
    };

    return {
      success: true,
      analytics: analytics,
    };
  } catch (error) {
    logger.error("Analytics error:", error);
    throw new Error(`Analytics calculation failed: ${error}`);
  }
});

// Email service functions (using Blaze plan external API access)
async function sendVerificationEmail(email: string, name: string, verificationLink: string) {
  // Configure your email service (e.g., SendGrid, Mailgun, etc.)
  const transporter = nodemailer.createTransport({
    // Add your email service configuration here
    service: 'gmail', // or your preferred service
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  const mailOptions = {
    from: 'noreply@fedha-tracker.com',
    to: email,
    subject: 'Verify Your Fedha Account',
    html: `
      <h2>Welcome to Fedha, ${name}!</h2>
      <p>Please verify your email address by clicking the link below:</p>
      <a href="${verificationLink}" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Verify Email</a>
      <p>If you didn't create this account, please ignore this email.</p>
    `,
  };

  await transporter.sendMail(mailOptions);
}

async function sendWelcomeEmail(email: string, name: string, profileId: string) {
  // Similar email configuration for welcome email
  logger.info(`Sending welcome email to ${email} for profile ${profileId}`);
}

async function sendPasswordResetEmail(email: string, name: string, resetLink: string) {
  // Similar email configuration for password reset
  logger.info(`Sending password reset email to ${email}`);
}

// Analytics helper functions
function calculateAccountAge(createdAt: any): number {
  if (!createdAt) return 0;
  const created = createdAt.toDate();
  const now = new Date();
  return Math.floor((now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24));
}

function calculateDaysSinceLastLogin(lastLogin: any): number {
  if (!lastLogin) return -1;
  const login = lastLogin.toDate();
  const now = new Date();
  return Math.floor((now.getTime() - login.getTime()) / (1000 * 60 * 60 * 24));
}

function calculateProfileCompleteness(profile: any): number {
  const fields = ['name', 'email', 'profileType', 'baseCurrency'];
  const completedFields = fields.filter(field => profile[field] && profile[field] !== '');
  return Math.round((completedFields.length / fields.length) * 100);
}

function calculateRiskScore(profile: any): string {
  // Simple risk calculation - can be enhanced
  const age = calculateAccountAge(profile.createdAt);
  const completeness = calculateProfileCompleteness(profile);
  
  if (age > 30 && completeness > 80) return 'LOW';
  if (age > 7 && completeness > 60) return 'MEDIUM';
  return 'HIGH';
}

async function logAnalyticsEvent(eventName: string, data: any) {
  // Log to external analytics service (Blaze plan allows external calls)
  logger.info(`Analytics Event: ${eventName}`, data);
}

// Helper functions
function generateProfileId(profileType: string): string {
  const prefix = profileType === "business" ? "B" : "P";
  const suffix = Math.random().toString(36).substring(2, 9).toUpperCase();
  return `${prefix}-${suffix}`;
}

function generateTempPassword(): string {
  return Math.random().toString(36).substring(2, 10);
}

async function hashPassword(password: string): Promise<string> {
  // Simple hash for demo - use bcrypt in production
  const crypto = require("crypto");
  return crypto.createHash("sha256").update(password + "fedha-salt").digest("hex");
}

async function verifyPassword(plaintext: string, hash: string): Promise<boolean> {
  const computedHash = await hashPassword(plaintext);
  return computedHash === hash;
}
