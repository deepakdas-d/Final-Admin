const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteUserFromAuth = functions.https.onCall(async (data, context) => {
  try {
    const uid = data.uid;
    if (!uid) {
      throw new functions.https.HttpsError("invalid-argument", "Missing UID");
    }

    await admin.auth().deleteUser(uid);
    return {message: `User with UID ${uid} deleted successfully`};
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
