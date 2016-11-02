//
//  ViewController.h
//  STMExample
//
//  Created by Tyler Clemens on 6/6/16.
//  Copyright © 2016 Tyler Clemens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STMRecordingOverlayViewController.h"

@interface ViewController : UIViewController<STMRecordingOverlayDelegate>
@property (nonatomic, strong) STMRecordingOverlayViewController *overlayController;
@property (weak, nonatomic) IBOutlet UITextField *handleTextField;
@end

