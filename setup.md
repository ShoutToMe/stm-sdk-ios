---
layout: home
---

# Setting up the Shout to Me iOS SDK

The following describes how to set up your iOS project to use the Shout to Me iOS SDK.

## Prerequisites
* A Shout to Me client access token
* A Shout to Me channel ID
* [Xcode](https://developer.apple.com/xcode/)

## iOS version requirement

The Shout to Me iOS SDK requires iOS 8.0 or greater.

## Installation

### CocoaPods
The easiest way to install STM is to use CocoaPods. To do so, simply add the following line to your Podfile:

`pod 'STM'`

### Manual Installation

The other way to install STM, is to drag and drop the Pod folder into your Xcode project. When you do so, check the "Copy items into destination group's folder" box.


## Client Access Token, Channel ID, and Push Notification App ID
Developers will need to get a client access token and a channel ID from Shout to Me in order to use this SDK.  A client
access token is used to authorize the client app in HTTP calls.  The channel ID represents a Shout to Me channel which
is linked to the broadcaster/podcaster's account.

If you would like to enable your application to receive push notifications, you will also need to provide an APNs certificate
 and get a push notification app ID.  This setting wires up the app to Shout to Me's push notification system.

You will need to [contact Shout to Me](http://www.shoutto.me/contact) in order to get the client access
  token, channel ID and push notification app ID. Once you receive these items from Shout to Me, you can
  initialize the Shout to Me SDK within the `didFinishLaunchingWithOptions` function in your AppDelegate.m.

```objc
//AppDelegate.m


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Initialize Shout To Me SDK, Replace with your Shout to Me token
  [STM initWithAccessToken:@"STM_ACCESS_TOKEN" andApplication:application andDelegate:self];
  // Optional, this will setup notifications from ShoutToMe (additional steps are required)
  [STM setupNotificationsWithApplication:application pushNotificationAppId:@"PUSH_NOTIFICATION_APP_ID"];
  // Initialize the STM Location manager, this will ask for the required permissions. Or you can ask for the required location permissions and call this after.
  [STMLocation initAll];

  // Set your channel Id
  [STM setChannelId:@"CHANNEL_ID"];

  return YES;
}
```

## Permissions

### Record Audio

Being that Shout to Me is an audio-based platform, this permission is considered required. Launching the recording
overlay without the permission will result in a error response indicating that the record audio permission is denied.

Add the following to your Info.plist to request permission to record.

[NSMicrophoneUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW25)

Set the value to something like: "Your microphone is used to allow you to shout to the station."

### Location

Use of location functionality is optional in the Shout to Me platform. However, if location permission is enabled,
the coordinates (lat/lon) of the person shouting are included with the Shout creation request and broadcasters will be
able to see the location of the user.  In addition, users will be enabled to receive geo-targeted messages from
broadcasters.

To enable location permissions, add the following to your Info.plist.

[NSLocationUsageDescription](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW27)
<br>
[NSLocationAlwaysUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18)

Both are strings and should be set to something like: "Your location is used to let the station know what part of
town you are in and so you can receive geo-targeted messages."

You then need to request permission from the user to use their location. You can use your own location manager to do this or you can use the Shout to Me SDK Location Manager.

Here's how to use the STM SDK Location Manager:

```objc
[[[STM location] locationManager] requestAlwaysAuthorization];
```

This will ask the user to use their location like so: ![Notification example](https://s3-us-west-2.amazonaws.com/sdk-public-images/notification-example.jpg)


If you already have a location manager and want to use that. Inside of the `didChangeAuthorizationStatus` callback, call this Shout to Me method. You will get an error back if the authorization status isn't `kCLAuthorizationStatusAuthorizedAlways` or the user has Location Services disabled.

```objc
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSError *error;
       [[STM location] startWithError:&error];
    }
}
```
