/*
 * check_itunes_artworks.m
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 6/21/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#include <stdio.h>

#import "iTunes.h"
#import "FLErrorPrinter.h"
#import "check_itunes_artworks.h"

void OSStatusToCharStar(OSStatus status, char str[5]) {
	if (status == noErr) {
		str[0] = 'n';
		str[1] = 'o';
		str[2] = 'E';
		str[3] = 'r';
	} else {
		str[0] = (status >> 24);
		str[1] = (status >> 16) - (str[0] << 8);
		str[2] = (status >> 8)  - (str[1] << 8) - (str[0] << 16);
		str[3] = (status >> 0)  - (str[2] << 8) - (str[1] << 16) - (str[0] << 24);
	}
	
	str[4] = '\0';
}

t_error check_selected_artworks(const t_prgm_options *options) {
	@autoreleasepool {
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
		if (![iTunes isRunning]) {
			fprintf(stderr, "***** Error: iTunes must be running to check artworks\n");
			return ERR_ITUNES_NOT_LAUNCHED;
		}
		
		FLErrorPrinter *errorPrinter = [[FLErrorPrinter alloc] initWithFormatCString:options->output_format
																								  encoding:NSUTF8StringEncoding];
		
		for (iTunesTrack *ft in [[iTunes selection] get]) {
			@autoreleasepool {
				/* We cannot directly use the ITunesFileTrack class. If we do, we get a link error when compiling. */
				if (![ft isKindOfClass:[NSClassFromString(@"ITunesFileTrack") class]] && ![ft isKindOfClass:[NSClassFromString(@"ITunesSharedTrack") class]]) {
					[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Not a File or Shared Track (Got an %@)", NSStringFromClass([ft class])] track:ft];
					continue;
				}
				
				SBElementArray *artworks = [ft artworks];
				if (artworks.count == 0)
					[errorPrinter printErrorWithMessage:@"No artworks" track:ft];
				
				if (options->verbose)
					[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Being treated. Has %lu artwork(s)", (unsigned long)artworks.count] track:ft];
				
				NSUInteger i = 0;
				for (iTunesArtwork *curArtwork in artworks) {
					++i;
					if (!options->check_all && i > 1) break;
					
					@autoreleasepool {
						if (options->check_embed && curArtwork.downloaded)
							[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Artwork %lu is not embedded in track", (unsigned long)i] track:ft];
						
						if (options->x_size > 0 || options->y_size > 0 || options->ratio >= 0) {
							NSImage *curImage = nil;
							id obj = [curArtwork data];
							if ([obj isKindOfClass:[NSAppleEventDescriptor class]]) {
								/* A weird thing this NSAppleEventDescriptor. It seems to be a bug in the
								 * 64-bits version of iTunes: the data method of iTunesArtwork returns an
								 * NSAppleEventDescriptor instead of an NSImage. I did not found a proper
								 * way to use this NSAppleEventDescriptor, so instead, I create a new
								 * NSImage from the rawData of the artwork. */
								curImage = [[NSImage alloc] initWithData:[curArtwork rawData]];
								[curImage autorelease];
								if (curImage == nil) {
									[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Cannot create an NSImage from the rawData of the current artwork"] track:ft];
									break;
								}
							} else if ([obj isKindOfClass:[NSImage class]]) {
								curImage = obj;
							} else {
								[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Unkown class for artwork data (expected NSImage or NSAppleEventDescriptor, got %@)", NSStringFromClass([obj class])] track:ft];
							}
							if (options->x_size > 0 && curImage.size.width != options->x_size)
								[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"X Size of artwork %lu is not correct (expected %lu, got %g)", (unsigned long)i, options->x_size, curImage.size.width] track:ft];
							if (options->y_size > 0 && curImage.size.height != options->y_size)
								[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Y Size of artwork %lu is not correct (expected %lu, got %g)", (unsigned long)i, options->y_size, curImage.size.height] track:ft];
							if (options->ratio >= 0 && !has_correct_ratio(curImage.size.width, curImage.size.height, options->ratio))
								[errorPrinter printErrorWithMessage:[NSString stringWithFormat:@"Ratio of artwork %lu is not correct (expected %g, got %g)", (unsigned long)i, options->ratio, curImage.size.width / curImage.size.height] track:ft];
						}
					}
				}
			}
		}
		
		[errorPrinter release];
	}
	
	return ERR_NO_ERR;
}
