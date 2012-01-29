/*
 * FileTransfer.m
 * FileTransfer
 * 
 * Created by Árpád Goretity on 02/01/2012.
 * Licensed under a CreativeCommons Attribution
 * 3.0 Unported License
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import "FTDefines.h"
#import "FTListener.h"

__ctor void init()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	FTListener *listener = [[FTListener alloc] init];
	[[LAActivator sharedInstance] registerListener:listener forName:@"org.h2co3.filetransfer"];
	[pool release];
}

