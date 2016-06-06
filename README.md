[![CocoaPods](https://img.shields.io/cocoapods/p/STM.svg)](https://cocoapods.org/pods/STM)
[![CocoaPods](https://img.shields.io/cocoapods/v/STM.svg)](https://cocoapods.org/pods/STM)
# Shout to Me iOS SDK

## Quickstart Guide
This guide will show you how to get up and running with the Shout to Me iOS SDK in minutes.

###  Prerequisites
* A Shout to Me client access token
* Xcode


#### 1.Start a new project
In Xcode, go to File > New > Project or press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd>. Select the Single View Application.

![New iOS Project](/screen-shots/new-project.png)

#### 2.Give your project a name

![Name Project](/screen-shots/project-name.png)

#### 3.Install STM iOS SDK

Using [CocoaPods](https://cocoapods.org/about):

Go to your project directory, use `pod init` to create a Podfile.

Add this line to your Podfile:

pod 'STM', '~> 0.0.12'

Then use `pod install` to install the pod and create an Xcode workspace.

**Close any current Xcode sessions and use `.xcworkspace` for this project from now on.**

#### 4. Edit Info.plist
The STM SDK requires two keys be added to your app's Info.plist.

[NSLocationUsageDescription](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW27)

[NSLocationWhenInUseUsageDescription](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW26)

Both are strings and should be set to: "Your location is used to find shouts near you."


#### 5.Initialize STM

Edit AppDelegate.m :

You’ll need your Shout to Me access token to access the API.

```objc
#import "AppDelegate.h"
#import "STM.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // This category is appropriate for simultaneous recording and playback, and also for apps that record and play back but not simultaneously.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    // Activates your app’s audio session.
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    // Replace with your Shout to Me token
    [STM sharedInstance].accessToken = @"YOUR_ACCESS_TOKEN";
    // Set your channel Id
    [STM sharedInstance].channelId = @"CHANNEL_ID";
    // Initialize Shout To Me SDK
    [STM initWithAccessToken:@"YourSTMAccessToken"];

    return YES;
}
```

#### 6. Use the Shout To Me Recording View Controller
The SDK provides a STMRecordingOverlay view controller to simplify recording shouts and sending them to the API.



```objc
//ViewController.h

// Add and implement the STMRecordingOverlayDelegate
@interface STMViewController : UIViewController <STMRecordingOverlayDelegate>

@end
```

```objc
//ViewController.m

@interface ViewController ()
// Create reference to overlay view controller
@property (nonatomic, strong) STMRecordingOverlayViewController *overlayController;
@end

@implementation ViewController

// Add a button and present the recording overlay when touched
- (IBAction)RecordTouched:(id)sender {
    self.overlayController = [[STMRecordingOverlayViewController alloc] init];
    self.overlayController.delegate = self;
    [self presentViewController:self.overlayController animated:YES completion:nil];

}

#pragma mark - STMRecordingOverlay delegate methods
-(void)shoutCreated:(STMShout*)shout error:(NSError*)err {
    if (err) {
        NSLog(@"[shoutCreated] error: %@", [err localizedDescription]);
        
    } else {
        NSLog(@"Shout Created with Id: %@", shout.str_id);
    }
}

```

## SDK Documentation
### STMRecordingOverlayDelegate
The STMRecordingOverlay delegate can be used to respond to recording events from the STMRecordingOverlayViewController.

```objc
/**
 * Delegates used by STMRecordingOverlayViewController to communicate recording events with the app
 */
@protocol STMRecordingOverlayDelegate <NSObject>

 /**
 * shoutCreated
 * Called after the response is received from a call to the create
 * shout server endpoint.  This includes the recorded audio being sent to
 * the server.
 * @param shout - the shout created
 * @param err - an error object
 */
-(void)shoutCreated:(STMShout*)shout error:(NSError*)err;

@end
```

##Release Workflow
```
$ cd ~/code/Pods/NAME
$ edit NAME.podspec
# set the new version to 0.0.1
# set the new tag to 0.0.1
$ pod lib lint

$ git add -A && git commit -m "Release 0.0.1."
$ git tag '0.0.1'
$ git push --tags
```
Once your tags are pushed you can use the command:
`pod trunk push NAME.podspec` to send your library to the Specs repo.
