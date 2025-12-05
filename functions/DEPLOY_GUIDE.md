# Quick Start: Deploy Push Notifications

## Step 1: Install Dependencies

```powershell
cd functions
npm install
```

## Step 2: Login to Firebase

```powershell
firebase login
```

## Step 3: Select Your Firebase Project

```powershell
firebase use --add
```

Select your project from the list and give it an alias (e.g., "default").

## Step 4: Deploy Cloud Functions

```powershell
firebase deploy --only functions
```

This command deploys all three Cloud Functions:
- `sendNotificationOnCreate`
- `sendNotificationOnOrderUpdate` 
- `sendNotificationOnTradeOfferUpdate`

## Step 5: Test the App

1. Run the app on a **physical device** (emulators don't support push notifications)
2. Log in with a test account
3. Create an order or trade offer from another device/account
4. You should receive a push notification on your phone!

## Verify Deployment

Check that functions are deployed successfully:

```powershell
firebase functions:list
```

You should see your three functions listed with status "ACTIVE".

## View Logs

To see what's happening with your functions:

```powershell
firebase functions:log
```

Or view in Firebase Console: **Functions** → **Logs**

## Common Issues

### Issue: "Firebase project not found"
**Solution:** Run `firebase use --add` and select your project

### Issue: "Permission denied"
**Solution:** Make sure you're logged in: `firebase login`

### Issue: "Function deployment failed"
**Solution:** 
1. Check Node.js version: `node --version` (should be 18+)
2. Delete `node_modules` and run `npm install` again
3. Check Firebase Console for any billing issues

### Issue: "Notifications not received"
**Solution:**
1. Check user has FCM token saved in Firestore (user-info collection)
2. Test on a physical device (not emulator)
3. Check notification permissions are enabled on the device
4. View function logs for errors: `firebase functions:log`

## Update Functions

If you make changes to the Cloud Functions:

```powershell
cd functions
firebase deploy --only functions
```

## Test Individual Functions

Deploy only one function:

```powershell
firebase deploy --only functions:sendNotificationOnCreate
```

## Pricing

**Good news!** The free tier includes:
- 2 million function invocations per month
- Unlimited FCM messages

For a small-to-medium app, you'll stay within the free tier.

## Next Steps

✅ Functions deployed
✅ App configured
✅ FCM tokens saved

Now test by:
1. Creating orders between users
2. Accepting/updating orders as a seller
3. Submitting and responding to trade offers

Check your phone for push notifications! 🔔
