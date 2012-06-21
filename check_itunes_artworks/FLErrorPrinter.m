/*
 * FLErrorPrinter.m
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 6/21/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#import "FLErrorPrinter.h"

@interface FLErrorPrinterComponent : NSObject

+ (FLErrorPrinterComponent *)component;

/* Abstract method */
- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track;

@end

@interface FLErrorPrinterLiteralComponent : FLErrorPrinterComponent

@property(copy) NSString *string;

+ (FLErrorPrinterLiteralComponent *)literalComponentWithString:(NSString *)str;

@end

@interface FLErrorPrinterErrorComponent : FLErrorPrinterComponent

@end

@interface FLErrorPrinterTitleComponent : FLErrorPrinterComponent

@end

@interface FLErrorPrinterArtistComponent : FLErrorPrinterComponent

@end

@interface FLErrorPrinterAlbumComponent : FLErrorPrinterComponent

@end

@interface FLErrorPrinterIdComponent : FLErrorPrinterComponent

@end

@interface FLErrorPrinterFilenameComponent : FLErrorPrinterComponent

@end

@implementation FLErrorPrinterComponent : NSObject

+ (FLErrorPrinterComponent *)component
{
	return [[[self alloc] init] autorelease];
}

/* Abstract method */
- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	[NSException raise:@"Abstract class" format:@"Method printComponentWithMessage:track: is abstract."];
}

@end

@implementation FLErrorPrinterLiteralComponent

@synthesize string;

+ (FLErrorPrinterLiteralComponent *)literalComponentWithString:(NSString *)str
{
	FLErrorPrinterLiteralComponent *c = [[[self alloc] init] autorelease];
	c.string = str;
	return c;
}

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterErrorComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[errMsg dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterTitleComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[track.name dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterArtistComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[track.artist dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterAlbumComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[track.album dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterIdComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	[fh writeData:[track.persistentID dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation FLErrorPrinterFilenameComponent

- (void)printComponentWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
	if (![track isKindOfClass:[NSClassFromString(@"ITunesFileTrack") class]])
		[fh writeData:[@"(Not a File Track)" dataUsingEncoding:NSUTF8StringEncoding]];
	else {
		iTunesFileTrack *ft = (iTunesFileTrack *)track;
		[fh writeData:[ft.location.absoluteString dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

@end

@implementation FLErrorPrinter

@synthesize format;

- (id)initWithFormat:(NSString *)f
{
	if ((self = [super init]) != nil) {
		printerComponents = [NSMutableArray new];
		self.format = f;
	}
	
	return self;
}

- (id)initWithFormatCString:(const char *)f encoding:(NSStringEncoding)encoding
{
	return [self initWithFormat:[NSString stringWithCString:f encoding:encoding]];
}

- (void)dealloc
{
	[printerComponents release];
	
	[super dealloc];
}

- (void)setFormatFromCString:(const char *)formatCString encoding:(NSStringEncoding)encoding
{
	self.format = [NSString stringWithCString:formatCString encoding:encoding];
}

#pragma mark - Overridden accessors

- (NSString *)format
{
	return [[format copy] autorelease];
}

- (void)setFormat:(NSString *)newFormat
{
	if (newFormat == format) return;
	
	[format release]; format = [newFormat copy];
	
	/* Computing components for format */
	[printerComponents removeAllObjects];
	NSUInteger curPos = 0;
	while (curPos < format.length) {
		NSRange r = [format rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(curPos, format.length - curPos)];
		if (r.location != NSNotFound && r.location != format.length - 1) {
			[printerComponents addObject:
			 [FLErrorPrinterLiteralComponent literalComponentWithString:
			  [format substringWithRange:NSMakeRange(curPos, r.location - curPos)]]];
			unichar formatLetter = [format characterAtIndex:r.location + 1];
			switch (formatLetter) {
				case 'e': [printerComponents addObject:[FLErrorPrinterErrorComponent component]];    break;
				case 't': [printerComponents addObject:[FLErrorPrinterTitleComponent component]];    break;
				case 'a': [printerComponents addObject:[FLErrorPrinterAlbumComponent component]];    break;
				case 's': [printerComponents addObject:[FLErrorPrinterArtistComponent component]];   break;
				case '#': [printerComponents addObject:[FLErrorPrinterIdComponent component]];       break;
				case 'f': [printerComponents addObject:[FLErrorPrinterFilenameComponent component]]; break;
				case '%': [printerComponents addObject:[FLErrorPrinterLiteralComponent literalComponentWithString:@"%"]]; break;
				default: /* Unknown format. Silently ignored. */;
			}
		} else {
			[printerComponents addObject:
			 [FLErrorPrinterLiteralComponent literalComponentWithString:
			  [format substringFromIndex:curPos]]];
		}
		if (r.location != NSNotFound) r.location += 2;
		curPos = r.location;
	}
	
	if (printerComponents.count > 0)
		[printerComponents addObject:[FLErrorPrinterLiteralComponent literalComponentWithString:@"\n"]];
}

#pragma mark - Actions

- (void)printErrorWithMessage:(NSString *)errMsg track:(iTunesTrack *)track
{
	for (FLErrorPrinterComponent *curComponent in printerComponents)
		[curComponent printComponentWithMessage:errMsg track:track];
}

@end
