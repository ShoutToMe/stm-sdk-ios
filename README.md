# Shout to Me iOS SDK
Version 1

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

pod 'STM', '~> 1.0.0'

Then use `pod install` to install the pod and create an Xcode workspace.

**Close any current Xcode sessions and use `.xcworkspace` for this project from now on.**

#### 4.Initialize STM

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
    [STM initAll];

    return YES;
}
```

#### 5. Use the Shout To Me Recording View Controller

-```objc
-//ViewController.h
-
-// Add and implement the STMRecordingOverlayDelegate
-@interface STMViewController : UIViewController <STMRecordingOverlayDelegate>
-
-@end
-```
The SDK provides a STMRecordingOverlay view controller to simplify recording shouts and sending them to the API.
```objc
//ViewController.m

@implementation ViewController

// Add a button and launch the recording overlay when touched
- (IBAction)RecordTouched:(id)sender {
    STMRecordingOverlayViewController *overlayViewController = [[STMRecordingOverlayViewController alloc] init];
    [self presentViewController:overlayViewController animated:NO completion:nil];

}

#pragma mark - STMRecordingOverlay delegate methods
-(void)shoutCreated:(Shout*)shout error:(NSError*)err {
    if (err) {
        NSLog(@"[shoutCreated] error: %@", [err localizedDescription]);
        return;
    }
    NSLog(@"Shout Created with Id: %@", shout.str_id);
}

-(void)shoutDeleted:(NSError*)err {
    if (err) {
        NSLog(@"[shoutDeleted] error: %@", [err localizedDescription]);
        return;
    }
    NSLog(@"Shout Deleted");
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
/**
 * shoutDeleted
 * Called after the response is received from a call to the delete
 * shout server endpoint.
 * @param err - an error object
 */
-(void)shoutDeleted:(NSError*)err;

@end
```

