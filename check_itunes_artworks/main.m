/*
 * main.m
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 4/5/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>
#include <getopt.h>

#import "iTunes.h"

#import "constants.h"
#import "free_const_char.h"

BOOL has_correct_ratio(NSUInteger x, NSUInteger y, CGFloat test_ratio) {
	return ABS((CGFloat)x / (CGFloat)y - test_ratio) <= MAX_DIFF_FOR_DOUBLE_EQUALITY;
}

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
	fprintf(out, "\n   -x x_size   --x-size=x_size\n   Sets the expected width of the artworks. Must be greater than 0.\n");
	fprintf(out, "\n   -y y_size   --y-size=y_size\n   Sets the expected height of the artworks. Must be greater than 0.\n");
	fprintf(out, "\n   -r ratio   --ratio=ratio\n   Sets the expected ratio of the artworks. Default is 1. Three formats are valid:\n");
	fprintf(out, "     • A float or integer which will represent the x/y ratio;\n");
	fprintf(out, "     • A string of the form \"x/y\" where x and y are floats or integers;\n");
	fprintf(out, "     • The string \"none\" if there are no requirements on the ratio.\n");
	fprintf(out, "\n   -a   --check-all\n   Set this flag to check all the artworks of the selected tracks. By default, only the first one is checked.\n");
	fprintf(out, "\n   -f format   --output-format=format\n   format is a printf-style format that will be used to output the tracks whose artwork does not fulfill the conditions. Default is '\"%%t — %%a — %%s\" does not fulfill the conditions'. Possible %%-escapes are:\n");
	fprintf(out, "     • %%t: Track title;\n");
	fprintf(out, "     • %%a: Track album;\n");
	fprintf(out, "     • %%s: Track artist;\n");
	fprintf(out, "     • %%#: Track ID in iTunes;\n");
	fprintf(out, "     • %%f: Track filename;\n");
	fprintf(out, "     • %%%%: A percent.\n");
	fprintf(out, "\n   -t\n   Set this flag to automatically answer yes to all questions.\n");
	
	return from_syntax_error? ERR_SYNTAX: ERR_NO_ERR;
}

NSString *trackDescrFrom(iTunesTrack *track) {
	return [NSString stringWithFormat:@"%@ — %@ — %@ (ID %@)", track.name, track.album, track.artist, track.persistentID];
}

int main(int argc, char * const * argv) {
	int getopt_long_ret;
	t_error ret = ERR_NO_ERR;
	BOOL parse_options_succeeded = YES;
	t_prgm_options options = {NO, 0, 0, 1., NO, NULL, NO};
	struct option long_options[] =
	{
		/* These options set a flag. */
		{"verbose",   no_argument, &options.verbose,   YES},
		{"check-all", no_argument, &options.check_all, YES},
		/* These options don't set a flag.
		 We distinguish them by their indices. */
		{"help",   no_argument,       NULL, 'h'},
		{"x-size", required_argument, NULL, 'x'},
		{"y-size", required_argument, NULL, 'y'},
		{"ratio",  required_argument, NULL, 'r'},
		{"format", required_argument, NULL, 'f'},
		{0, 0, 0, 0}
	};
	
	do {
		char *number_parse_check = NULL;
		
		/* getopt_long stores the option index here. */
		int option_index = 0;
		getopt_long_ret = getopt_long(argc, argv, "vathx:y:r:f:", long_options, &option_index);
		
		switch (getopt_long_ret) {
			case -1: break; /* End of options */
			case 0:
				/* If this option set a flag, it is here the "verbose" or "check-all" options and
				 * there is nothing else to do. */
				if (long_options[option_index].flag != NULL) break;
				
				/* All options that don't set a flag should return an indice
				 * (see the definition of the long_options array). */
				assert(0);
				break;
			case 'h':
				ret = usage(argv[0], NO);
				goto end;
				break;
			case 'v':
				options.verbose = YES;
				break;
			case 'a':
				options.check_all = YES;
				break;
			case 't':
				options.always_yes = YES;
				break;
			case 'x':
				options.x_size = (NSUInteger)strtol(optarg, &number_parse_check, 10);
				if (*number_parse_check != '\0') {
					fprintf(stderr, "%s: bad argument for the \"x-size\" option.\n", argv[0]);
					parse_options_succeeded = NO;
				}
				break;
			case 'y':
				options.y_size = (NSUInteger)strtol(optarg, &number_parse_check, 10);
				if (*number_parse_check != '\0') {
					fprintf(stderr, "%s: bad argument for the \"y-size\" option.\n", argv[0]);
					parse_options_succeeded = NO;
				}
				break;
			case 'r':
				options.ratio = (CGFloat)strtod(optarg, &number_parse_check);
				if (*number_parse_check == '/') {
					double y = (CGFloat)strtod(number_parse_check + 1, &number_parse_check);
					options.ratio /= y;
				}
				if (*number_parse_check != '\0') {
					fprintf(stderr, "%s: bad argument for the \"ratio\" option.\n", argv[0]);
					parse_options_succeeded = NO;
				}
				break;
			case 'f': {
				char *format_copy = malloc(sizeof(char)*(strlen(optarg) + 1));
				strcpy(format_copy, optarg);
				options.output_format = format_copy;
				break;
			}
			case '?':
				parse_options_succeeded = NO;
				break; /* getopt_long already printed an error message. */
			default:
				assert(0);
		}
	} while (getopt_long_ret != -1 && parse_options_succeeded);
	
	if (!parse_options_succeeded || optind != argc) {
		ret = usage(argv[0], YES);
		goto end;
	}
	
	if (options.output_format == NULL) {
		const char *default_format = "\"%t — %a — %s\" does not fulfill the conditions";
		char *default_format_copy = malloc(sizeof(char)*(strlen(default_format) + 1));
		strcpy(default_format_copy, default_format);
		options.output_format = default_format_copy;
	}
	
	if (options.verbose) {
		fprintf(stderr, "Easter egg: verbose mode is activated!\n");
		fprintf(stderr, "Options:\n");
		fprintf(stderr, "   x-size:        ");
		if (options.x_size > 0) fprintf(stderr, "%lu\n", (unsigned long)options.x_size);
		else                    fprintf(stderr, "not checked\n");
		fprintf(stderr, "   y-size:        ");
		if (options.y_size > 0) fprintf(stderr, "%lu\n", (unsigned long)options.y_size);
		else                    fprintf(stderr, "not checked\n");
		fprintf(stderr, "   ratio:         ");
		if (options.ratio >= 0.) fprintf(stderr, "%g\n", options.ratio);
		else                     fprintf(stderr, "not checked\n");
		fprintf(stderr, "   output format: \"%s\"\n", options.output_format);
		fprintf(stderr, "   \"check all artworks\" is %s\n", options.check_all? "true": "false");
		fprintf(stderr, "   \"yes to all\"         is %s\n", options.always_yes? "true": "false");
		fprintf(stderr, "\n");
	}
	
	if (options.x_size > 0 && options.y_size > 0 && options.ratio >= 0.) {
		if (!has_correct_ratio(options.x_size, options.y_size, options.ratio))
			fprintf(stderr, "Warning: checked ratio is not equal to checked x size divided by checked y size\n");
	}
	goto end;
	
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
	
end:
	if (options.output_format != NULL) free_const_char(options.output_format);
	return ret;
}
