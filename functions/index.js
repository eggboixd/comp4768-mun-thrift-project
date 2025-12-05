const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Send push notification when a new notification is created in Firestore
 */
exports.sendNotificationOnCreate = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      try {
        const notificationData = event.data.data();
        const userId = notificationData.userId;

        // Get user's FCM token from user-info collection
        const userDoc = await admin
            .firestore()
            .collection("user-info")
            .doc(userId)
            .get();

        if (!userDoc.exists) {
          console.log(`User ${userId} not found`);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token found for user ${userId}`);
          return null;
        }

        // Prepare notification payload
        const payload = {
          token: fcmToken,
          notification: {
            title: notificationData.title || "New Notification",
            body: notificationData.message || "",
          },
          data: {
            notificationId: event.params.notificationId,
            type: notificationData.type || "general",
            orderId: notificationData.orderId || "",
            tradeOfferId: notificationData.tradeOfferId || "",
            fromUserId: notificationData.fromUserId || "",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              sound: "default",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send notification
        const response = await admin.messaging().send(payload);
        console.log(
            `Successfully sent notification to ${userId}: ${response}`,
        );

        return response;
      } catch (error) {
        console.error("Error sending notification:", error);
        return null;
      }
    },
);

/**
 * Send push notification when an order status is updated
 */
exports.sendNotificationOnOrderUpdate = onDocumentUpdated(
    "orders/{orderId}",
    async (event) => {
      try {
        const before = event.data.before.data();
        const after = event.data.after.data();

        // Check if status changed
        if (before.status === after.status) {
          return null;
        }

        const buyerId = after.buyerId;
        const orderId = event.params.orderId;
        const newStatus = after.status;

        // Get buyer's FCM token
        const userDoc = await admin
            .firestore()
            .collection("user-info")
            .doc(buyerId)
            .get();

        if (!userDoc.exists) {
          console.log(`Buyer ${buyerId} not found`);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token found for buyer ${buyerId}`);
          return null;
        }

        // Determine notification title and message based on status
        let title = "";
        let message = "";

        switch (newStatus) {
          case "confirmed":
            title = "Order Confirmed";
            message =
              "Your order has been confirmed and is being prepared.";
            break;
          case "preparing":
            title = "Order Preparing";
            message = "The seller is preparing your order.";
            break;
          case "shipped":
            title = "Order Shipped";
            message = "Your order has been shipped!";
            break;
          case "inDelivery":
            title = "Order In Delivery";
            message = "Your order is on the way to you.";
            break;
          case "completed":
            title = "Order Completed";
            message = "Your order has been delivered. Enjoy!";
            break;
          case "cancelled":
            title = "Order Cancelled";
            message = "Your order has been cancelled.";
            break;
          default:
            return null;
        }

        // Prepare notification payload
        const payload = {
          token: fcmToken,
          notification: {
            title: title,
            body: message,
          },
          data: {
            type: "orderUpdate",
            orderId: orderId,
            status: newStatus,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              sound: "default",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send notification
        const response = await admin.messaging().send(payload);
        console.log(
            `Successfully sent order update notification to ${buyerId}: ${response}`,
        );

        return response;
      } catch (error) {
        console.error("Error sending order update notification:", error);
        return null;
      }
    },
);

/**
 * Send push notification when a trade offer status is updated
 */
exports.sendNotificationOnTradeOfferUpdate = onDocumentUpdated(
    "tradeOffers/{tradeOfferId}",
    async (event) => {
      try {
        const before = event.data.before.data();
        const after = event.data.after.data();

        // Check if status changed
        if (before.status === after.status) {
          return null;
        }

        const buyerId = after.buyerId; // Person who made the trade offer
        const tradeOfferId = event.params.tradeOfferId;
        const newStatus = after.status;
        const requestedItemTitle = after.requestedItemTitle;

        // Get buyer's FCM token
        const userDoc = await admin
            .firestore()
            .collection("user-info")
            .doc(buyerId)
            .get();

        if (!userDoc.exists) {
          console.log(`Buyer ${buyerId} not found`);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token found for buyer ${buyerId}`);
          return null;
        }

        // Determine notification title and message based on status
        let title = "";
        let message = "";

        switch (newStatus) {
          case "accepted":
            title = "Trade Offer Accepted!";
            message =
              `Your trade offer for "${requestedItemTitle}" has been accepted!`;
            break;
          case "rejected":
            title = "Trade Offer Declined";
            message =
              `Your trade offer for "${requestedItemTitle}" has been declined.`;
            if (after.sellerResponse) {
              message += ` Reason: ${after.sellerResponse}`;
            }
            break;
          default:
            return null;
        }

        // Prepare notification payload
        const payload = {
          token: fcmToken,
          notification: {
            title: title,
            body: message,
          },
          data: {
            type: "tradeOfferUpdate",
            tradeOfferId: tradeOfferId,
            status: newStatus,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              sound: "default",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send notification
        const response = await admin.messaging().send(payload);
        console.log(
            `Successfully sent trade offer update notification to ${buyerId}: ${response}`,
        );

        return response;
      } catch (error) {
        console.error("Error sending trade offer update notification:", error);
        return null;
      }
    },
);
