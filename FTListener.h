/*
 * FTListener.h
 * FileTransfer
 *
 * Created by Árpád Goretity on 28/01/2012.
 * Licensed under a CreativeCommons Attribution
 * 3.0 Unporter License
 */

#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>
#import "FTViewController.h"


@interface FTListener: NSObject <LAListener> {
	FTViewController *ctrl;
}

- (void) makeVc;

@end
