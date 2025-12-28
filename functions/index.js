const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();
/**
 * TRIGGER 2: Firestore - Notify on New Ride
 * Runs when a new document is added to the 'rides' collection.
 */
exports.notifyNewRide = functions.firestore
  .document("rides/{rideId}")
  .onCreate(async (snapshot, context) => {
    const rideData = snapshot.data();
    const creatorId = rideData.userId; // ID of the person who posted the ride

    try {
      // 1. Fetch all users who have an FCM token
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("fcmToken", "!=", null) 
        .get();

      const tokens = [];
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        
        // 2. Only add tokens for OTHER users (don't notify the creator)
        if (userData.fcmToken && doc.id !== creatorId) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No recipient tokens found.");
        return null;
      }

      // 3. Prepare the message payload
      // Note: We use sendEachForMulticast for multiple tokens
      const message = {
        notification: {
          title: "New Ride Available! 🚗",
          body: `Destination: ${rideData.destination || "A new ride was posted!"}`,
        },
        tokens: tokens,
      };

      // 4. Send notifications
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Successfully sent ${response.successCount} notifications.`);

      return null;
    } catch (error) {
      console.error("Error in notifyNewRide function:", error);
      return null;
    }
  });