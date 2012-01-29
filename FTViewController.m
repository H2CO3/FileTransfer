/*
 * FTViewController.m
 * FileTransfer
 * 
 * Created by Árpád Goretity on 02/01/2012.
 * Licensed under a CreativeCommons Attribution 3.0 Unported License
 */

#import <signal.h>
#import <sys/stat.h>
#import <QuartzCore/QuartzCore.h>
#import "FTViewController.h"

#define FLOATDIV(x, y) (((float)(x)) / ((float)(y)))
#define FTBasePath @"/var/mobile/Library/FileTransfer"


@class UIKeyboard;

@implementation FTViewController

- (id) init
{
	if ((self = [super init]))
	{
		self.title = @"FileTransfer";
		UIImage *bgImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FTDarkBackground" ofType:@"png"]];
		self.view.backgroundColor = [UIColor colorWithPatternImage:bgImage];
		[bgImage release];
		CGRect frm = self.view.frame;
		frm.origin.y = 20.0 - [UIScreen mainScreen].bounds.size.height;
		self.view.frame = frm;
		
		/* ignore SIGPIPE; TCPHelper already handles I/O errors, and we don't wanna crash */
		signal(SIGPIPE, SIG_IGN);
		
		UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		closeButton.frame = CGRectMake(0.0, 440.0, 320.0, 20.0);
		UIImage *closeImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FTClose" ofType:@"png"]];
		[closeButton setImage:closeImage forState:UIControlStateNormal];
		[closeImage release];
		[closeButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:closeButton];
		
		UIImage *buttonImageUnstrechable = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FTButton" ofType:@"png"]];
		UIImage *buttonImage = [buttonImageUnstrechable stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
		[buttonImageUnstrechable release];

		select = [UIButton buttonWithType:UIButtonTypeCustom];
		select.frame = CGRectMake(20.0, 20.0, 280.0, 44.0);
		[select setTitle:L(@"Choose a file to send") forState:UIControlStateNormal];
		[select setBackgroundImage:buttonImage forState:UIControlStateNormal];
		select.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		[select addTarget:self action:@selector(chooseFile) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:select];

		/* Host and port text inputs */
		host = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 100.0, 280.0, 29.0)];
		host.textColor = [UIColor whiteColor];
		host.font = [UIFont boldSystemFontOfSize:16.0];
		host.delegate = self;
		host.placeholder = L(@"Enter host name or IP");
		[self.view addSubview:host];
		[host release];
		
		port = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 145.0, 280.0, 29.0)];
		port.textColor = [UIColor whiteColor];
		port.font = [UIFont boldSystemFontOfSize:16.0];
		port.delegate = self;
		port.placeholder = L(@"Enter port number");
		port.text = @"5555";
		[self.view addSubview:port];
		[port release];
		
		tcpHelper = [[TCPHelper alloc] initWithHost:host.text port:port.text];
		tcpHelper.timeout = 60.0;
		tcpHelper.delegate = self;
		tcpHelper.chunkSize = 128 * 1024; /* receive and send data in 128 kB chunks */
		
		/* Send and Receive buttons */
		send = [UIButton buttonWithType:UIButtonTypeCustom];
		send.enabled = NO;
		send.frame = CGRectMake(20.0, 360.0, 130.0, 44.0);
		[send setTitle:L(@"Send file") forState:UIControlStateNormal];
		[send setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
		[send setBackgroundImage:buttonImage forState:UIControlStateNormal];
		send.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		[send addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:send];
		
		receive = [UIButton buttonWithType:UIButtonTypeCustom];
		receive.enabled = NO;
		receive.frame = CGRectMake(170.0, 360.0, 130.0, 44.0);
		[receive setTitle:L(@"Receive file") forState:UIControlStateNormal];
		[receive setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
		[receive setBackgroundImage:buttonImage forState:UIControlStateNormal];
		receive.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		[receive addTarget:self action:@selector(receive) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:receive];
		
		/* Status indicators */
		notificationView = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 10.0, 280.0, 44.0)];
		notificationView.font = [UIFont boldSystemFontOfSize:18.0];
		notificationView.textAlignment = UITextAlignmentCenter;
		notificationView.backgroundColor = [UIColor clearColor];
		notificationView.textColor = [UIColor darkGrayColor];
		
		notificationBackground = [[UIView alloc] initWithFrame:CGRectMake(160.0, 232.0, 0.0, 0.0)];
		notificationBackground.backgroundColor = [UIColor grayColor];
		notificationBackground.backgroundColor = [UIColor whiteColor];
		notificationBackground.layer.cornerRadius = 8.0;
		notificationBackground.layer.shadowOffset = CGSizeMake(4.0, 4.0);
		notificationBackground.layer.shadowOpacity = 0.4;
		notificationBackground.layer.shadowColor = [UIColor whiteColor].CGColor;
		notificationBackground.layer.shadowRadius = 4.0;
		notificationBackground.alpha = 0.0;
		[notificationBackground addSubview:notificationView];
		[self.view addSubview:notificationBackground];
		
		progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20.0, 300.0, 280.0, 29.0)];
		progressView.hidden = YES;
		progressView.backgroundColor = [UIColor clearColor];
		[self.view addSubview:progressView];
	}
	return self;
}	

- (void) dealloc
{
	[file release];
	[tcpHelper release];
	[notificationView release];
	[notificationBackground release];
	[progressView release];
	[super dealloc];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	/* make the keyboard appear correctly */
	[self showKeyboard:YES animated:YES];
	[self showKeyboard:NO animated:YES];
}

- (void) showKeyboard:(BOOL)show animated:(BOOL)animate
{
	UIKeyboard *key = NULL;
	
	if ([UIKeyboard respondsToSelector:@selector(automaticKeyboard)])
	{
		key = [UIKeyboard automaticKeyboard];
	}
	else
	{
		key = [UIKeyboard activeKeyboard];
	}

	if (!key)
	{
		key = [[[UIKeyboard alloc] initWithDefaultSize] autorelease];
		if ([UIApplication sharedApplication].keyWindow) {
			[[UIApplication sharedApplication].keyWindow addSubview:key];
		} else if ([[[UIApplication sharedApplication] windows] count]) {
			[[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:key];
		} else {
			NSLog(@"Error: cannot add keyboard to key window");
		}
	}

	if (show) 
	{
		if ([key respondsToSelector:@selector(orderInWithAnimation:)])
		{
			[key orderInWithAnimation:animate];
		}
		else
		{
			[key activate];
			[key minimize];
			[key maximize];
		}
	}
	else
	{
		if ([key respondsToSelector:@selector(orderOutWithAnimation:)])
		{
			[key orderOutWithAnimation:animate];
		}
		else
		{
			[key minimize];
			[key deactivate];
		}
	}
}

- (void) toggle
{
	if (showing)
	{
		[self done];
	}
	else
	{
		[self show];
	}
}

- (void) show
{
	if (showing)
	{
		return;
	}
	showing = YES;
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:0.5];
	CGRect frame = self.view.frame;
	frame.origin.y = 20.0;
	self.view.frame = frame;
	[UIView commitAnimations];
	[self enableControls:YES];
}

- (void) done
{
	if (!showing)
	{
		return;
	}
	showing = NO;
	[self enableControls:NO];
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:0.5];
	CGRect frame = self.view.frame;
	frame.origin.y = 20.0 - [UIScreen mainScreen].bounds.size.height;
	self.view.frame = frame;
	[UIView commitAnimations];
}

- (void) send
{
	[tcpHelper startServer];
}

- (void) receive
{
	[tcpHelper connectToServer];
}

- (void) removeNotification
{
	notificationView.text = NULL;
	[UIView beginAnimations:NULL context:NULL];
	notificationBackground.alpha = 0.0;
	notificationBackground.frame = CGRectMake(160.0, 232.0, 0.0, 0.0);
	[UIView commitAnimations];
}

- (void) showNotification
{
	[UIView beginAnimations:NULL context:NULL];
	notificationBackground.alpha = 1.0;
	notificationBackground.frame = CGRectMake(20.0, 200.0, 280.0, 64.0);
	[UIView commitAnimations];
}

- (void) handleErrorMessage:(NSString *)message
{
	[self removeNotification];
	[[[[UIAlertView alloc] initWithTitle:message message:NULL delegate:NULL cancelButtonTitle:L(@"Dismiss") otherButtonTitles:NULL] autorelease] show];
}

- (void) enableControls:(BOOL)flag
{
	host.enabled = flag;
	port.enabled = flag;
	select.enabled = flag;
	receive.enabled = [port.text length] && [host.text length] ? flag : NO;
	send.enabled = [port.text length] && file ? flag : NO;
}

- (void) updateProgress:(NSNumber *)progressNum
{
	progressView.progress = [progressNum floatValue];
}

- (void) chooseFile
{
	FTChooseViewController *chooser = [[FTChooseViewController alloc] init];
	chooser.delegate = self;
	UINavigationController *chNav = [[UINavigationController alloc] initWithRootViewController:chooser];
	[chooser release];
	chNav.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:chNav animated:YES];
	[chNav release];
}

/* FTChooseViewControllerDelegate */

- (void) chooser:(FTChooseViewController *)chooser choseFile:(NSString *)filePath
{
	[file release];
	file = [filePath retain];
	/* update UI */
	[select setTitle:[filePath lastPathComponent] forState:UIControlStateNormal];
	[self enableControls:YES];
	[self dismissModalViewControllerAnimated:YES];
}

- (void) chooserCancelled:(FTChooseViewController *)chooser
{
	/* update UI */
	[self enableControls:YES];
	[self dismissModalViewControllerAnimated:YES];
}

/* UITextFieldDelegate */

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
	[self showKeyboard:YES animated:YES];
	return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	[self showKeyboard:NO animated:YES];

	if ([port.text length])
	{
		if (file)
		{
			send.enabled = YES;
		}
		else
		{
			send.enabled = NO; /* cannot send nonexistent file */
		}
		if ([host.text length])
		{
			receive.enabled = YES;
		}
		else
		{
			receive.enabled = NO; /* cannot receive without server name */
		}
	}
	else
	{
		send.enabled = NO; /* cannot send without port */
		receive.enabled = NO; /* cannot receive without port */
	}
	
	/* Update TCPHelper with the new host/port info */
	[tcpHelper release];
	tcpHelper = [[TCPHelper alloc] initWithHost:host.text port:port.text];
	tcpHelper.timeout = 60.0;
	tcpHelper.delegate = self;
	
	return YES;
}

/* TCPHelperDelegate */

- (void) tcpHelperStartedRunning:(TCPHelper *)helper
{
	[self showNotification];
	notificationView.text = L(@"Connecting...");
	[self enableControls:NO]; /* no user action while transferring */
}

- (void) tcpHelperConnected:(TCPHelper *)helper
{
	totalsize = 0;
	NSMutableData *data = [[NSMutableData alloc] init];
	progressView.hidden = NO;
	progressView.progress = 0.0;
	
	if ([helper isServer])
	{
		notificationView.text = L(@"Sending file...");
		
		/*
		 * Data format:
		 * 256-byte NUL-terminated filename
		 * 8-byte unsigned integer filesize
		 * following (filesize) bytes: actual file data
		 */
		NSMutableString *fileName = [[file lastPathComponent] mutableCopy];
		if ([fileName length] > sizeof(header.filename))
		{
			[fileName deleteCharactersInRange:NSMakeRange(sizeof(header.filename) - 1, [fileName length] - (sizeof(header.filename) - 1))];
		}
		NSData *filenameData = [fileName dataUsingEncoding:NSUTF8StringEncoding];		
		[fileName release];
		memset(header.filename, 0, sizeof(header.filename));
		memcpy(header.filename, [filenameData bytes], [filenameData length]);
		[data appendBytes:header.filename length:sizeof(header.filename)];

		struct stat buf;
		stat([file UTF8String], &buf);
		header.filesize = buf.st_size;
		[data appendBytes:&header.filesize length:sizeof(header.filesize)];

		NSData *fileContents = [[NSData alloc] initWithContentsOfFile:file];
		[data appendData:fileContents];
		[fileContents release];
		[tcpHelper sendData:data];
		[data release];
	}
	else
	{
		notificationView.text = L(@"Receiving file...");
		header.filesize = 0;
		hasHeader = NO;
		headerData = [[NSMutableData alloc] init];
		[tcpHelper receiveData];
	}
}

- (void) tcpHelper:(TCPHelper *)helper receivedData:(NSData *)data
{
	totalsize += [data length];
	
	if (!hasHeader)
	{
		/* header not yet fully received */
		[headerData appendData:data];
		if (totalsize >= (sizeof(header.filename) + sizeof(header.filesize)))
		{
			/*
			 * Data format:
			 * 256-byte NUL-terminated filename
			 * 8-byte unsigned integer filesize
			 * following (filesize) bytes: actual file data
			 */
			memcpy(header.filename, [data bytes], sizeof(header.filename));
			memcpy(&header.filesize, [data bytes] + sizeof(header.filename), sizeof(header.filesize));
			hasHeader = YES;
			[headerData release];
			
			NSString *targetFileName = [FTBasePath stringByAppendingPathComponent:[NSString stringWithUTF8String:header.filename]];
			[[NSFileManager defaultManager] removeItemAtPath:targetFileName error:NULL];
			[[NSFileManager defaultManager] createFileAtPath:targetFileName contents:NULL attributes:NULL];
			fileHandle = [NSFileHandle fileHandleForWritingAtPath:targetFileName];
			
			NSData *fraction = [[NSData alloc] initWithBytes:[data bytes] + sizeof(header.filename) + sizeof(header.filesize) length:[data length] - (sizeof(header.filename) + sizeof(header.filesize))];
			[fileHandle writeData:fraction];
			[fraction release];
			
			return;
		}
	}
	/* header fully received, write actual file data */
	[fileHandle writeData:data];
	/* and finally update progress bar */
	float progress = FLOATDIV(totalsize - (sizeof(header.filename) + sizeof(header.filesize)), header.filesize);
	NSNumber *num = [[NSNumber alloc] initWithFloat:progress];
	/* UIKit requires operations on the main thread */
	[self performSelectorOnMainThread:@selector(updateProgress:) withObject:num waitUntilDone:NO];
	[num release];
}

- (void) tcpHelper:(TCPHelper *)helper sentData:(NSData *)data
{
	/* nothing to do, just update progress bar */
	totalsize += [data length];
	float progress = FLOATDIV(totalsize - (sizeof(header.filename) + sizeof(header.filesize)), header.filesize);
	NSNumber *num = [[NSNumber alloc] initWithFloat:progress];
	/* UIKit requires operations on the main thread */
	[self performSelectorOnMainThread:@selector(updateProgress:) withObject:num waitUntilDone:NO];
	[num release];
}

- (void) tcpHelperFinishedReceivingData:(TCPHelper *)helper
{
	/* clean up */
	[helper disconnect];
	[fileHandle closeFile];
	[self removeNotification];
	progressView.hidden = YES;
	[self enableControls:YES];
	NSString *targetFileName = [FTBasePath stringByAppendingPathComponent:[NSString stringWithUTF8String:header.filename]];
	[[[[UIAlertView alloc] initWithTitle:L(@"File saved to:") message:targetFileName delegate:NULL cancelButtonTitle:L(@"Dismiss") otherButtonTitles:NULL] autorelease] show];
}

- (void) tcpHelperFinishedSendingData:(TCPHelper *)helper
{
	/* clean up */
	[helper disconnect];
	progressView.hidden = YES;
	[self enableControls:YES];
	[self removeNotification];
}

- (void) tcpHelper:(TCPHelper *)helper errorOccurred:(NSError *)error
{
	/* clean up */
	[helper disconnect];
	progressView.hidden = YES;
	[self removeNotification];
	[self enableControls:YES];
	[self handleErrorMessage:[[error userInfo] objectForKey:TCPHelperErrorDescriptionKey]];
}

@end

