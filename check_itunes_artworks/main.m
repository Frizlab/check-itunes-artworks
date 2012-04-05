/*
 * main.m
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 4/5/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "iTunes.h"

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

NSString *trackDescrFrom(iTunesTrack *track) {
	return [NSString stringWithFormat:@"%@ — %@ — %@ (ID %@)", track.name, track.album, track.artist, track.persistentID];
}

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
		if (![iTunes isRunning]) {
			NSLog(@"*** Error: iTunes must be running for the script to work");
			return 42;
		}
		
		for (iTunesTrack *ft in [[iTunes selection] get]) {
			@autoreleasepool {
				
				if (![[ft className] isEqualToString:@"ITunesFileTrack"]) {
					NSLog(@"*** Warning: Skipping track %@ as it is not a file track", ft.name);
					continue;
				}
				
				SBElementArray *artworks = [ft artworks];
				if (artworks.count == 0)
					NSLog(@"*** Warning: Track %@ does not have any artworks", trackDescrFrom(ft));
				
				NSUInteger i = 0;
				for (iTunesArtwork *curArtwork in artworks) {
					++i;
					NSImage *curImage = [curArtwork data];
					if (curImage.size.width != curImage.size.height)
						NSLog(@"*** Warning: Artwork %lu of track %@ is not a square", (unsigned long)i, trackDescrFrom(ft));
				}
				
			}
		}
	}
	
	return 0;
}
