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
@property double MaxListeningSeconds;
@property NSString *tags;
@property NSString *topic;

-(void)userRequestsStopListening;
-(id)initWithTags:(NSString *)tags andTopic:(NSString *)topic;
@end

@protocol STMRecordingOverlayDelegate <NSObject>


-(void)shoutCreated:(STMShout*)shout error:(NSError*)err;
-(void)overlayClosed:(BOOL)bDismissed;
@end
