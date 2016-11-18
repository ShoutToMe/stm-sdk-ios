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

1. Import "STMRecordingOverlayViewController.h" to the header of your view controller:

    ```objc
    //ViewController.h

    #import <STMRecordingOverlayViewController.h>
    ```
2. Implement the STMRecordingOverlayDelegate:
    ```objc
    //ViewController.h

    @interface ViewController : UIViewController<STMRecordingOverlayDelegate>

    @end
    ```

3. Call the Recording overlay, in this case when a button is touched. Before calling the recording overlay, ensure that your app has mic permissions.
    ```objc
    - (IBAction)recordTouched:(id)sender {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Permission granted");
                NSError *error;
                [STM presentRecordingOverlayWithViewController:self andTags:nil andTopic:nil andMaxListeningSeconds:nil andDelegate:self andError:&error];
