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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordTouched:(id)sender {
    NSError *error;
    [STM presentRecordingOverlayWithViewController:self andTags:@"tag1, tag2" andTopic:@"custom topic" andMaxListeningSeconds:[NSNumber numberWithDouble:30.0] andDelegate:self andError:&error];
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
