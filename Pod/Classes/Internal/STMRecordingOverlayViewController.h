//
//  STMRecordingOverlayViewController.h
//  Pods
//
//  Created by Tyler Clemens on 9/14/15.
//
//

#import <UIKit/UIKit.h>
#import "VoiceCmdView.h"

@protocol STMRecordingOverlayDelegate;

@interface STMRecordingOverlayViewController : UIViewController<VoiceCmdViewDelegate, SendShoutDelegate>
@property (atomic) id<STMRecordingOverlayDelegate> delegate;
@end

@protocol STMRecordingOverlayDelegate <NSObject>

-(void)shoutCreated:(STMShout*)shout error:(NSError*)err;
@end