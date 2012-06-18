/*
 * main.m
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 4/5/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "iTunes.h"

#import "constants.h"

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

t_error usage(const char *progname, BOOL from_syntax_error) {
	FILE *out = stdout;
	if (from_syntax_error) out = stderr;
	
	fprintf(out, "usage: %s [option ...]\n", progname);
	fprintf(out, "\nThis tool will check the artworks of the selected tracks in your iTunes library for certain conditions.\n");
	fprintf(out, "\nOptions:\n");
	fprintf(out, "\n   -h   --help\n   Display this help and exit.\n");
	fprintf(out, "\n   -x x_size   --x-size=x_size\n   Sets the expected width of the artworks.\n");
	fprintf(out, "\n   -y y_size   --y-size=y_size\n   Sets the expected height of the artworks.\n");
	fprintf(out, "\n   -r ratio   --ratio=ratio\n   Sets the expected ratio of the artworks. Default is 1. Three formats are valid:\n");
	fprintf(out, "     • A float or integer which will represent the x/y ratio;\n");
	fprintf(out, "     • A string of the form \"x/y\" where x and y are floats or integers;\n");
	fprintf(out, "     • The string \"none\" if there are no requirements on the ratio.\n");
	fprintf(out, "\n   -a   --check-all\n   Set this flag to check all the artworks of the selected tracks. By default, only the first one is checked.\n");
	fprintf(out, "\n   -f format   --output-format=format\n   format is a printf-style format that will be used to output the tracks whose artwork does not fulfill the conditions. Possible %%-escapes are:\n");
	fprintf(out, "     • %%t: Track title;\n");
	fprintf(out, "     • %%a: Track album;\n");
	fprintf(out, "     • %%s: Track artist;\n");
	fprintf(out, "     • %%#: Track ID in iTunes;\n");
	fprintf(out, "     • %%f: Track filename.\n");
	fprintf(out, "\n   -y\n   Set this flag to automatically answer yes to all questions.\n");
	
	return from_syntax_error? ERR_SYNTAX: ERR_NO_ERR;
}

NSString *trackDescrFrom(iTunesTrack *track) {
	return [NSString stringWithFormat:@"%@ — %@ — %@ (ID %@)", track.name, track.album, track.artist, track.persistentID];
}

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
		if (![iTunes isRunning]) {
			NSLog(@"*** Error: iTunes must be running for the script to work");
			return ERR_ITUNES_NOT_LAUNCHED;
		}
		
		for (iTunesTrack *ft in [[iTunes selection] get]) {
			@autoreleasepool {
				/* We cannot directly use the ITunesFileTrack class. If we do, we get a link error when compiling. */
				if (![ft isKindOfClass:[NSClassFromString(@"ITunesFileTrack") class]]) {
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
	
	return ERR_NO_ERR;
}
