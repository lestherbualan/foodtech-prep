import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();

setGlobalOptions({
  maxInstances: 1,
  region: "asia-southeast1",
});

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/**
 * Generates a daily board exam countdown message.
 * @param {Date} examDate Target exam date.
 * @param {Date} [now=new Date()] Current date.
 * @param {string | undefined} userName Optional user display name.
 * @return {{title: string, body: string}} Reminder title and body.
 */
function buildCountdownReminder(
  examDate: Date,
  now: Date = new Date(),
  userName?: string,
): { title: string; body: string } {
  const examDay = new Date(
    examDate.getFullYear(),
    examDate.getMonth(),
    examDate.getDate(),
  );
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffMs = examDay.getTime() - today.getTime();
  const daysLeft = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  const greeting = userName ? `Hi ${userName}! ` : "";

  if (daysLeft <= 0) {
    return {
      title: "Exam Day!",
      body:
        `${greeting}The Food Technologist Board Exam is today. ` +
        "You've got this! 💪",
    };
  }

  if (daysLeft === 1) {
    return {
      title: "1 Day Left!",
      body:
        `${greeting}The Food Technologist Board Exam is tomorrow. ` +
        "Final review time!",
    };
  }

  return {
    title: `${daysLeft} Days Until the Board Exam`,
    body:
      `${greeting}${daysLeft} days until the Food Technologist ` +
      "Board Exam. Take a timed exam tonight.",
  };
}

// ---------------------------------------------------------------------------
// Shared notification target loader
// ---------------------------------------------------------------------------

/**
 * Loads a user's notification target data from Firestore
 * and validates that the user is eligible to receive push
 * notifications.
 * @param {string} uid The user ID to load.
 * @return {Promise<{userData: FirebaseFirestore.DocumentData,
 *   fcmToken: string}>} The validated user data and stored
 *   FCM token.
 */
async function getEligibleUserNotificationTarget(
  uid: string,
): Promise<{ userData: FirebaseFirestore.DocumentData; fcmToken: string }> {
  const userDoc = await admin.firestore().collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new HttpsError(
      "not-found",
      `User document not found for uid: ${uid}`,
    );
  }

  const userData = userDoc.data();
  if (!userData) {
    throw new HttpsError(
      "not-found",
      `User data not available for uid: ${uid}`,
    );
  }

  if (userData.notificationsEnabled !== true) {
    throw new HttpsError(
      "failed-precondition",
      "Notifications are disabled for this user.",
    );
  }

  const fcmToken = userData.fcmToken as string | undefined;
  if (!fcmToken || fcmToken.trim().length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No FCM token stored for this user.",
    );
  }

  return {userData, fcmToken};
}

// ---------------------------------------------------------------------------
// sendNotificationToUser — clean send-by-uid pattern
// ---------------------------------------------------------------------------

export const sendNotificationToUser = onCall(async (request) => {
  const data = request.data as {
    uid?: string;
    title?: string;
    body?: string;
  };

  const uid = data?.uid?.trim();
  const title = data?.title?.trim();
  const body = data?.body?.trim();

  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  if (!title || !body) {
    throw new HttpsError(
      "invalid-argument",
      "title and body are required.",
    );
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const callerUid = request.auth.uid;
  const isSelf = callerUid === uid;

  if (!isSelf) {
    const callerDoc = await admin.firestore()
      .collection("users").doc(callerUid).get();
    const callerRole = callerDoc.data()?.role as string | undefined;

    if (callerRole !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "You can only send notifications to your own account " +
        "unless you are a super admin.",
      );
    }
  }

  const {fcmToken} = await getEligibleUserNotificationTarget(uid);

  try {
    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: {title, body},
      data: {
        type: "notification",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {priority: "high"},
    });

    logger.info("Notification sent to user", {uid, messageId});

    return {success: true, messageId};
  } catch (error) {
    logger.error("Failed to send notification to user", {uid, error});
    throw new HttpsError("internal", "Failed to send notification.");
  }
});

// ---------------------------------------------------------------------------
// sendCountdownReminder — send daily countdown to a single user by uid
// ---------------------------------------------------------------------------

export const sendCountdownReminder = onCall(async (request) => {
  const data = request.data as {
    uid?: string;
    examDate?: string;
  };

  const uid = data?.uid?.trim();
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  if (request.auth.uid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "You can only send notifications for your own account.",
    );
  }

  const examDate =
    data?.examDate != null ?
      new Date(data.examDate) :
      new Date(2026, 9, 18);

  if (isNaN(examDate.getTime())) {
    throw new HttpsError("invalid-argument", "Invalid examDate format.");
  }

  const {userData, fcmToken} = await getEligibleUserNotificationTarget(uid);
  const displayName = userData.displayName as string | undefined;
  const reminder = buildCountdownReminder(examDate, new Date(), displayName);

  try {
    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: reminder.title,
        body: reminder.body,
      },
      data: {
        type: "countdown_reminder",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {priority: "high"},
    });

    const daysLeft = Math.ceil(
      (examDate.getTime() - new Date().getTime()) /
      (1000 * 60 * 60 * 24),
    );

    logger.info("Countdown reminder sent", {uid, messageId, daysLeft});

    return {success: true, messageId, daysLeft};
  } catch (error) {
    logger.error("Failed to send countdown reminder", {uid, error});
    throw new HttpsError("internal", "Failed to send countdown reminder.");
  }
});

// ---------------------------------------------------------------------------
// sendTestNotification — original raw-token test function (kept for debugging)
// ---------------------------------------------------------------------------

export const sendTestNotification = onCall(async (request) => {
  const data = request.data as {
    token?: string;
    title?: string;
    body?: string;
  };

  const token = data?.token?.trim();
  const title = data?.title?.trim() || "FoodTech Prep Test";
  const body = data?.body?.trim() || "This is a test notification.";

  if (!token) {
    throw new HttpsError("invalid-argument", "FCM token is required.");
  }

  try {
    const messageId = await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data: {
        type: "test",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
      },
    });

    logger.info("Test notification sent successfully", {
      messageId,
    });

    return {
      success: true,
      messageId,
    };
  } catch (error) {
    logger.error("Failed to send test notification", error);

    throw new HttpsError(
      "internal",
      "Failed to send test notification.",
    );
  }
});
