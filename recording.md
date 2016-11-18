---
layout: home
---

# Recording

<p align="center">
![Recording Overlay 1](https://github.com/ShoutToMe/stm-sdk-ios/blob/master/screen-shots/stm-recording-overlay-view-controller.png | height = 300px)
![Recording Overlay 2](https://github.com/ShoutToMe/stm-sdk-ios/blob/master/screen-shots/stm-recording-overlay-view-controller-sending.png | height = 300px)
</p>

The SDK provides a `STMRecordingOverlay` view controller to simplify recording shouts and sending them to the API.
Follow the steps below to set-up and use the overlay.

___

### Import "STMRecordingOverlayViewController.h" to the header of your view controller:

```objc
//ViewController.h

#import <STMRecordingOverlayViewController.h>
```

### Implement the STMRecordingOverlayDelegate:

```objc
//ViewController.h

@interface ViewController : UIViewController<STMRecordingOverlayDelegate>

@end
```

### Call the Recording overlay, in this case when a button is touched. Before calling the recording overlay, ensure that your app has mic permissions.

```objc
- (IBAction)recordTouched:(id)sender {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Permission granted");
                NSError *error;
                [STM presentRecordingOverlayWithViewController:self andTags:nil andTopic:nil andMaxListeningSeconds:nil andDelegate:self andError:&error];

                if (error) {
                    NSLog(@"%@", error.description);
                }
            });
        }
        else {
            NSLog(@"Permission denied");
        }
    }];
}
```


### [*Optional*] Delegates that you can listen to:

```objc
#pragma mark - STMRecordingOverlay delegate methods
/**
* shoutCreated
* Called after the response is received from a call to the create
* shout server endpoint.  This includes the recorded audio being sent to
* the server.
* @param shout - the shout created
* @param err - an error object
*/
-(void)shoutCreated:(STMShout*)shout error:(NSError*)err {
    if (err) {
        NSLog(@"[shoutCreated] error: %@", [err localizedDescription]);
    } else {
        NSLog(@"Shout Created with Id: %@", shout.str_id);
    }
}
/**
* overlayClosed
* Called when the STMRecordingOverlay has been closed
* @param bDismissed - true if the user clicked the top right close button or
*                     the audio was too short.
*/
- (void)overlayClosed:(BOOL)bDismissed {
    NSLog(@"bDismissed: %d", bDismissed);
}
```