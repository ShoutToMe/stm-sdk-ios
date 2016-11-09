//
//  ViewController.m
//  STMExample
//
//  Created by Tyler Clemens on 6/6/16.
//  Copyright © 2016 Tyler Clemens. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.handleTextField.text = [STM currentUser].strHandle;
    
    // Ask the user for location permissions
    [[[STM location] locationManager] requestAlwaysAuthorization];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (IBAction)UpdateTouched:(id)sender {
    if (self.handleTextField.text.length > 0) {
        [[STM signIn] setHandle:self.handleTextField.text withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error:  %@", [error userInfo]);
            } else {
                NSLog(@"Updated User handle!");
            }
        }];
    }
}


#pragma mark - STMRecordingOverlay delegate methods
-(void)shoutCreated:(STMShout*)shout error:(NSError*)err {
    if (err) {
        NSLog(@"[shoutCreated] error: %@", [err localizedDescription]);
    } else {
        NSLog(@"Shout Created with Id: %@", shout.str_id);
    }
}

- (void)overlayClosed:(BOOL)bDismissed {
    NSLog(@"bDismissed: %d", bDismissed);
//    self.overlayController = nil;
}

@end
