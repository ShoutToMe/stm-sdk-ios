//
//  ViewController.m
//  STMExample
//
//  Created by Tyler Clemens on 6/6/16.
//  Copyright © 2016 Tyler Clemens. All rights reserved.
//

#import "ViewController.h"
#import "STM.h"

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

- (IBAction)uploadShout:(id)sender {
    [self startMediaBrowserFromViewController:self usingDelegate:self];
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController *)controller usingDelegate:(id)delegate {
    // Validations
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    
    // Get image picker
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = delegate;
    
    // Display image picker
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"%@", info);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *localFileURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [[STM shout] uploadFromFile:localFileURL text:nil tags:@"Tag 1, Tag 2" topic:@"My topic" withDelegate:self];
}

- (IBAction)UpdateTouched:(id)sender {
    
    SetUserPropertiesInput *setUserPropertiesInput = [SetUserPropertiesInput new];
    [setUserPropertiesInput setHandle:self.handleTextField.text];
    
    // Delete properties with nil or an empty string
    [setUserPropertiesInput setEmail:@""];
    [setUserPropertiesInput setPhoneNumber:nil];
    
    [[STM user] setProperties:setUserPropertiesInput withCompletionHandler:^(NSError *error, id obj) {
        if (error) {
            NSLog(@"Error: %@", [error userInfo]);
        } else {
            NSLog(@"Updated user handle!");
            STMUser *user = (STMUser *)obj;
            NSLog(@"%@", user);
        }
    }];
}


#pragma mark - Create shout delegate methods
-(void)shoutCreated:(STMShout*)shout error:(NSError*)err {
    if (err) {
        NSLog(@"[shoutCreated] error: %@", [err localizedDescription]);
    } else {
        NSLog(@"Shout Created with Id: %@", shout.str_id);
    }
}

// Overlay only
- (void)overlayClosed:(BOOL)bDismissed {
    NSLog(@"bDismissed: %d", bDismissed);
//    self.overlayController = nil;
}


@end
