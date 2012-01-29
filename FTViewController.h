/*
 * FTViewController.h
 * FileTransfer
 * 
 * Created by Árpád Goretity on 02/01/2012.
 * Licensed under a CreativeCommons Attribution 3.0 Unported License
 */

#import <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FTDefines.h"
#import "FTChooseViewController.h"
#import "TCPHelper/TCPHelper.h"


/*
 * Data format:
 * 256-byte NUL-terminated filename
 * 8-byte unsigned integer filesize
 * following (filesize) bytes: actual file data
*/
typedef struct {
	char filename[256];
	uint64_t filesize;
} FTHeader;


@interface FTViewController: UIViewController <TCPHelperDelegate, UITextFieldDelegate, FTChooseViewControllerDelegate> {
	NSString *file;
	FTHeader header;
	uint64_t totalsize;
	NSMutableData *headerData;
	BOOL hasHeader;
	NSFileHandle *fileHandle;
	TCPHelper *tcpHelper;
	UITextField *host;
	UITextField *port;
	UIButton *send;
	UIButton *receive;
	UIButton *select;
	UILabel *notificationView;
	UIView *notificationBackground;
	UIProgressView *progressView;
	BOOL showing;
}

- (void) show;
- (void) done;
- (void) toggle;
- (void) showKeyboard:(BOOL)show animated:(BOOL)animate;

- (void) send;
- (void) receive;

- (void) handleErrorMessage:(NSString *)message;
- (void) enableControls:(BOOL)flag;
- (void) showNotification;
- (void) removeNotification;

@end

