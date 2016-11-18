---
layout: home
---

# Sample App

The iOS sample app included with this project demonstrates how to correctly setup and use the SDK. The example app can
be found under the [Example directory](https://github.com/ShoutToMe/stm-sdk-ios/tree/master/Example).  Follow the steps
below to create your own sample app.

1. Edit Info.plist
    * Add the location permissions keys.

        [NSLocationUsageDescription](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW27)

        [NSLocationAlwaysUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18)

        Both are strings and should be set to something like: "Your location is used to let the station know what part of
        town you are in and so you can receive geo-targeted messages."

    * Add the record audio key.

        [NSMicrophoneUsageDescription](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW25)

        Set to something like: "Your microphone is used to allow you to shout to the station."

2. Import "STM.h" to the header of AppDelegate.h:
```objc
//AppDelegate.h

#import <STM.h>
```

3. Initialize STM SDK within `didFinishLaunchingWithOptions` in your AppDelegate.m
  ```objc
  //AppDelegate.m


  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

      // Initialize Shout To Me SDK, Replace with your Shout to Me token
      [STM initWithAccessToken:@"STM_ACCESS_TOKEN" andApplication:application andDelegate:self];
      // Optional, this will setup notifications from ShoutToMe (additional steps are required)
      [STM setupNotificationsWithApplication:application];
      // Initialize the STM Location manager, this will ask for the required permissions. Or you can ask for the required location permissions and call this after.
      [STMLocation initAll];

      // Set your channel Id
      [STM setChannelId:@"CHANNEL_ID"];

      return YES;
  }
  ```

You will now be able to use the Shout to Me SDK in your app.