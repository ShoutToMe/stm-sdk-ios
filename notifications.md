---
layout: home
---

# Messages and Notifications

The Shout to Me platform allows you to enable your app to receive communications sent from Shout to Me's Broadcaster
Application.  Messages and notifications are two separate concepts in the Shout to Me system.  A **Message** is text or
audio content that is sent to mobile users to convey a communication.  A **Notification** (which is taken from the mobile
technology term "Push Notification") is the delivery mechanism used to transport a Message.

## Messages
The SDK provides a Messages class that can be used to retrieve Messages for the current user, or check if they have
unread messages.

```objc
// Request all of the users messages for the current user.
- (void)requestForMessagesWithDelegate:(id<MessagesDelegate>)delegate;
// Request the count of unread messages for the current user.
- (void)requestForUnreadMessageCountWithDelegate:(id<MessagesDelegate>)delegate;
// Request a specific message by Id
- (void)requestForMessage:(NSString *)messageId completionHandler:(void (^)(STMMessage *message,
                                                                            NSError *error))completionHandler;
```

### Retrieving messages

#### Import "STM.h" to the header of your view controller:

```objc
//ViewController.h

#import <STM.h>
```

#### Implement the MessagesDelegate:

```objc
//ViewController.h

@interface ViewController : UIViewController<MessagesDelegate>

@end
```

#### Request messages in your ViewController:

```objc
//ViewController.m

- (void)viewDidLoad {
    [super viewDidLoad];
    [[STM messages] requestForMessagesWithDelegate:self];
}
```

#### Implement MessagesDelegate MessagesResults delegate:

```objc
//ViewController.m

#pragma mark - Messages Delegates
- (void)MessagesResults:(NSArray *)arrayMessages
{
    // Do something with arrayMessages, load them into a table view data source...ect

    // Update the user's LastReadMessages date
    // If this is not updated, the call to requestForUnreadMessageCountWithDelegate will return
    // the same number even after the user views their messages.
    [[STM signIn] setLastReadMessages:[NSDate date] withDelegate:self];
}
```

### Get Unread Message Count

#### Import "STM.h" to the header of your view controller:

```objc
//ViewController.h

#import <STM.h>
```

#### Implement the MessagesDelegate:
```objc

//ViewController.h

@interface ViewController : UIViewController<MessagesDelegate>

@end
```

#### Request unread message count in your ViewController:

```objc
//ViewController.m

- (void)viewDidLoad {
    [super viewDidLoad];
    [[STM messages] requestForUnreadMessageCountWithDelegate:self];
}
```

#### Implement MessagesDelegate UnreadMessageResults delegate:

```objc
//ViewController.m

#pragma mark - Messages Delegates
- (void)UnreadMessageResults:(NSNumber *)count {
    // Do something with count, like setting a label's text, ect...
}
```


## Notifications
The Shout to Me SDK supports receiving push notifications from the Shout to Me platform.  The SDK will only handle
  notifications sent from the Shout to Me system.  There are a number of technologies used in receiving notifications,
  and consequently, there are a number of items that need to be wired up. The following high level steps occur in the
  notifications system:

1. A message is sent from the Shout to Me Broadcaster Application
2. The message is delivered to the mobile app as a Google Cloud Messaging notification
3. The Shout to Me SDK receives the notification and broadcasts a message
4. A listener in the client app receives a broadcast and can take further action using the data

![Notifications](https://s3-us-west-2.amazonaws.com/sdk-public-images/android-notifications.png)

### Google Cloud Messaging
The Shout to Me system uses [Google Cloud Messaging (GCM)](https://developers.google.com/cloud-messaging/) to send and receive messages. Add the following to your AndroidManifest.xml if you wish to receive notifications.  Be sure to set your own values for the string resource references.  Check with Shout to Me support for specific values to use.

```xml
<service
    android:name="me.shoutto.sdk.GcmNotificationRegistrationIntentService"
    android:exported="false">
    <meta-data android:name="me.shoutto.sdk.GcmDefaultSenderId" android:value="@string/gcm_default_sender_id" />
    <meta-data android:name="me.shoutto.sdk.PlatformApplicationArn" android:value="@string/platform_application_arn" />
    <meta-data android:name="me.shoutto.sdk.IdentityPoolId" android:value="@string/identity_pool_id" />
</service>

<!-- [START gcm_receiver] -->
<receiver
    android:name="com.google.android.gms.gcm.GcmReceiver"
    android:exported="true"
    android:permission="com.google.android.c2dm.permission.SEND">
    <intent-filter>
        <action android:name="com.google.android.c2dm.intent.RECEIVE" />
        <category android:name="me.shoutto.sdk" />
    </intent-filter>
</receiver>
<!-- [END gcm_receiver] -->


<!-- [START gcm_listener] -->
<service
    android:name="me.shoutto.sdk.StmGcmListenerService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.android.c2dm.intent.RECEIVE" />
    </intent-filter>
</service>
<!-- [END gcm_listener] -->


<!-- [START instanceId_listener] -->
<service
    android:name="me.shoutto.sdk.GcmInstanceIDListenerService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.android.gms.iid.InstanceID" />
    </intent-filter>
</service>
<!-- [END instanceId_listener] -->
```

### Geofencing
Location based notifications will be created as [geofences](https://developers.google.com/android/reference/com/google/android/gms/location/Geofence) in the Shout to Me SDK.  Add this to your AndroidManifest.xml to allow the SDK to listen for geofence events:

```xml
<service android:name="me.shoutto.sdk.GeofenceTransitionsIntentService" />
```

**Note:** Please contact Shout to Me support if you are already using geofences within your application.

### Shout to Me Broadcasts
The Shout to Me SDK uses a standard Android broadcast to send the processed message data to client apps.  Add the following to your AndroidManifest.xml to listen for these broadcasts.

```xml
<receiver
    android:name=".StmNotificationReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="me.shoutto.sdk.EVENT_MESSAGE_NOTIFICATION_RECEIVED" />
    </intent-filter>
</receiver>
```

Of course, you will need to supply your own listener class. In this example, it is called StmNotificationReceiver.

The broadcast receiver class should include something similar to the following to retrieve the broadcast data:

```java
@Override
public void onReceive(Context context, Intent intent) {
    Bundle data = intent.getExtras();
    body = data.getString(MessageNotificationIntentWrapper.EXTRA_NOTIFICATION_BODY);
    channelId = data.getString(MessageNotificationIntentWrapper.EXTRA_CHANNEL_ID);
    channelImageUrl = data.getString(MessageNotificationIntentWrapper.EXTRA_CHANNEL_IMAGE_URL);
    title = data.getString(MessageNotificationIntentWrapper.EXTRA_NOTIFICATION_TITLE);
    type = data.getString(MessageNotificationIntentWrapper.EXTRA_NOTIFICATION_TYPE);
}
```


