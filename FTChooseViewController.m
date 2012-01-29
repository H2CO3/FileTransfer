/*
 * FTChooseViewController.m
 * FileTransfer
 *
 * Created by Árpád Goretity on 28/01/2012.
 * Licensed under a CreativeCommons Attribution
 * 3.0 Unported License
 */

#import "FTChooseViewController.h"
#import "FTDefines.h"

#define RGBA(r, g, b, a) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:(a)]
#define FTLastDirKey @"FTLastDirKey"


@implementation FTChooseViewController

@synthesize	extensions = extensions,
		delegate = delegate;

- (id) init
{
	if ((self = [super init]))
	{
		self.navigationItem.title = L(@"Choose file");
		self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
		NSString *lastDir = [[NSUserDefaults standardUserDefaults] objectForKey:FTLastDirKey];
		if (![lastDir length])
		{
			lastDir = @"/";
		}
		cwd = [[NSString alloc] initWithString:lastDir];
		fileManager = [NSFileManager defaultManager];
		contents = [[NSMutableArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:cwd error:NULL]];
		[self sortDirContents];

		fileIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FTFileIcon" ofType:@"png"]];
		dirIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FTDirIcon" ofType:@"png"]];

		UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
		self.navigationItem.rightBarButtonItem = cancel;
		[cancel release];

		UIBarButtonItem *up = [[UIBarButtonItem alloc] initWithTitle:L(@"Up") style:UIBarButtonItemStyleBordered target:self action:@selector(goUp)];
		self.navigationItem.leftBarButtonItem = up;
		[up release];
		
		cwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
		cwdLabel.textColor = [UIColor lightGrayColor];
		cwdLabel.textAlignment = UITextAlignmentCenter;
		cwdLabel.text = cwd;
		self.tableView.tableFooterView = cwdLabel;
	}
	return self;
}

- (void) dealloc
{
	self.extensions = NULL;
	[contents release];
	[cwd release];
	[fileIcon release];
	[dirIcon release];
	[cwdLabel release];
	[super dealloc];
}

- (void) loadDir:(NSString *)dir
{
	NSString *tmp = [[NSString alloc] initWithString:[cwd stringByAppendingPathComponent:dir]];
	[cwd release];
	cwd = tmp;
	[contents setArray:[fileManager contentsOfDirectoryAtPath:cwd error:NULL]];
	[self sortDirContents];
	cwdLabel.text = cwd;
	[[NSUserDefaults standardUserDefaults] setObject:cwd forKey:FTLastDirKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self.tableView reloadData];
}

- (void) goUp
{
	NSString *tmp = [[NSString alloc] initWithString:[cwd stringByDeletingLastPathComponent]];
	[cwd release];
	cwd = tmp;
	[contents setArray:[fileManager contentsOfDirectoryAtPath:cwd error:NULL]];
	[self sortDirContents];
	cwdLabel.text = cwd;
	[[NSUserDefaults standardUserDefaults] setObject:cwd forKey:FTLastDirKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self.tableView reloadData];
}

- (void) cancel
{
	[self.delegate chooserCancelled:self];
}

- (void) sortDirContents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *dirs = [[NSMutableArray alloc] init];
	NSMutableArray *files = [[NSMutableArray alloc] init];
	
	for (int i = 0; i < [contents count]; i++)
	{
		NSString *fileName = [contents objectAtIndex:i];
		NSString *path = [cwd stringByAppendingPathComponent:fileName];
		BOOL isDir = NO;
		[fileManager fileExistsAtPath:path isDirectory:&isDir];
		if (isDir) {
			[dirs addObject:fileName];
		} else {
			[files addObject:fileName];
		}
	}
	
	[dirs sortUsingSelector:@selector(compare:)];
	[files sortUsingSelector:@selector(compare:)];
	[contents removeAllObjects];
	[contents addObjectsFromArray:dirs];
	[contents addObjectsFromArray:files];
	
	[dirs release];
	[files release];
	[pool release];
}

/* UITableViewDelegate */

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	NSString *fileName = [contents objectAtIndex:indexPath.row];
	NSString *path = [cwd stringByAppendingPathComponent:fileName];
	BOOL isDir = NO;
	[fileManager fileExistsAtPath:path isDirectory:&isDir];

	if (isDir) {
		[self loadDir:fileName];
	} else {
		[self.delegate chooser:self choseFile:path];
	}
}

- (BOOL) tableView:(UITableView *)tableView canSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.extensions)
	{
		NSString *fileName = [contents objectAtIndex:indexPath.row];
		NSString *path = [cwd stringByAppendingPathComponent:fileName];
		if (![self.extensions containsObject:[path pathExtension]])
		{
			return NO;
		}
	}
	return YES;
}

/* UITableViewDataSource */

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [contents count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.textColor = RGBA(0.0, 0.0, 0.0, 1.0);
	cell.imageView.alpha = 1.0;

	NSString *fileName = [contents objectAtIndex:indexPath.row];
	NSString *path = [cwd stringByAppendingPathComponent:fileName];
	BOOL isDir = NO;
	[fileManager fileExistsAtPath:path isDirectory:&isDir];

	if (isDir) {
		cell.imageView.image = dirIcon;
	} else {
		cell.imageView.image = fileIcon;
	}

	if (self.extensions)
	{
		if (![self.extensions containsObject:[path pathExtension]])
		{
			cell.textLabel.textColor = RGBA(0.0, 0.0, 0.0, 0.75);
			cell.imageView.alpha = 0.75;
		}
	}

	cell.textLabel.text = fileName;

	return cell;
}

@end

