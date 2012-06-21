/*
 * FLErrorPrinter.h
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 6/21/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "iTunes.h"

@interface FLErrorPrinter : NSObject {
	NSMutableArray *printerComponents;
}
@property(copy) NSString *format;

/* Designate initializer */
- (id)initWithFormat:(NSString *)f;
- (id)initWithFormatCString:(const char *)f encoding:(NSStringEncoding)encoding;

- (void)setFormatFromCString:(const char *)formatCString encoding:(NSStringEncoding)encoding;

/* Actions */

- (void)printErrorWithMessage:(NSString *)errMsg track:(iTunesTrack *)track;

@end
