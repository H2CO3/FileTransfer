/*
 * FTChooseViewController.h
 * FileTransfer
 *
 * Created by Árpád Goretity on 28/01/2012.
 * Licensed under a CreativeCommons Attribution
 * 3.0 Unported License
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FTChooseViewController;

@protocol FTChooseViewControllerDelegate <NSObject>
- (void) chooser:(FTChooseViewController *)chooser choseFile:(NSString *)fileName;
- (void) chooserCancelled:(FTChooseViewController *)chooser;
@end

@interface FTChooseViewController: UITableViewController {
	NSArray *extensions;
	NSString *cwd;
	NSMutableArray *contents;
	NSFileManager *fileManager;
	UIImage *fileIcon;
	UIImage *dirIcon;
	UILabel *cwdLabel;
	id <FTChooseViewControllerDelegate> delegate;
}

@property (nonatomic, retain) NSArray *extensions;
@property (nonatomic, assign) id <FTChooseViewControllerDelegate> delegate;

- (void) loadDir:(NSString *)dir;
- (void) goUp;
- (void) sortDirContents;

@end

