---
layout: home
---

# Sample App

The iOS sample app included with this project demonstrates how to correctly setup and use the SDK. The example app can
be found under the [Example directory](https://github.com/ShoutToMe/stm-sdk-ios/tree/master/Example).  Follow the steps
below to create your own sample app.

## Edit Info.plist

* Add the location permissions keys.

    [NSLocationUsageDescription](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW27)

    [NSLocationAlwaysUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18)

    Both are strings and should be set to something like: "Your location is used to let the station know what part of
    town you are in when you shout and to allow you to receive location-specific messages."

* Add the record audio key.

    [NSMicrophoneUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW25)

    Set to something like: "Your microphone is used to allow you to send audio to us."

## Import "STM.h" to the header of AppDelegate.h:

```objc
//AppDelegate.h

#import <STM.h>
```

## Initialize STM SDK within `didFinishLaunchingWithOptions` in your AppDelegate.m

```objc
//AppDelegate.m


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Initialize Shout To Me SDK, Replace with your Shout to Me token
  [STM initWithAccessToken:@"STM_ACCESS_TOKEN" andApplication:application andDelegate:self];

  // Optional, this will setup notifications from ShoutToMe (additional steps are required. See the Messages and Notifications section in documentation)
  [STM setupNotificationsWithApplication:application pushNotificationAppId:@"PUSH_NOTIFICATION_APP_ID"];

  // Set your channel Id
  [STM setChannelId:@"CHANNEL_ID"];

  return YES;
}
```

You will now be able to use the Shout to Me SDK in your app.