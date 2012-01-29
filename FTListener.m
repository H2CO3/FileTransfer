/*
 * FTListener.h
 * FileTransfer
 *
 * Created by Árpád Goretity on 28/01/2012.
 * Licensed under a CreativeCommons Attribution
 * 3.0 Unporter License
 */

#import "FTListener.h"
#import "FTViewController.h"


@implementation FTListener

- (void) makeVc
{
	ctrl = [[FTViewController alloc] init];
	if ([UIApplication sharedApplication].keyWindow) {
		[[UIApplication sharedApplication].keyWindow addSubview:ctrl.view];
	} else if ([[UIApplication sharedApplication].windows count]) {
		[[[UIApplication sharedApplication].windows objectAtIndex:0] addSubview:ctrl.view];
	} else {
		NSLog(@"FileTransfer: error: cannot attach to key window");
	}
}

- (void) activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if (!ctrl)
	{
		[self makeVc];
	}
	[ctrl toggle];
}

- (void) dealloc
{
	[ctrl release];
	[super dealloc];
}

@end
