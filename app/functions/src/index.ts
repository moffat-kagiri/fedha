/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

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
    await sendPasswordResetEmail(email, profile.name, profile.id, tempPassword);

    response.status(200).json({
      message: "If an account exists with this email, password reset instructions have been sent.",
    });

  } catch (error) {
    logger.error("Password reset error:", error);
    response.status(500).json({error: "Failed to process password reset"});
  }
});

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

async function sendPasswordResetEmail(email: string, name: string, profileId: string, tempPassword: string): Promise<void> {
  try {
    // For production deployment, set up nodemailer with Firebase config:
    // firebase functions:config:set gmail.user="gaussanalyticske@gmail.com"
    // firebase functions:config:set gmail.password="your-gmail-app-password"
    
    // For now, log credentials for manual support via gaussanalyticske@gmail.com
    logger.info(`Password reset requested for ${email}. Credentials for manual support:`);
    logger.info(`Name: ${name}, Profile ID: ${profileId}, Temp Password: ${tempPassword}`);
    logger.info(`Support team: Please send the above credentials to ${email} manually via gaussanalyticske@gmail.com`);
    
  } catch (error) {
    logger.error("Password reset function error:", error);
    logger.info(`MANUAL SUPPORT NEEDED - Email: ${email}, Profile ID: ${profileId}, Temp Password: ${tempPassword}`);
  }
}
