/*
 * constants.h
 * check-itunes-artworks
 *
 * Created by François LAMBOLEY on 6/18/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#ifndef check_itunes_artworks_constants_h
# define check_itunes_artworks_constants_h

/* Because struct option wants an int instead of booleans */
# define BOOL int

# define MAX_DIFF_FOR_DOUBLE_EQUALITY (.000001)

typedef enum e_error {
	ERR_NO_ERR = 0,
	ERR_SYNTAX = 1,
	ERR_ITUNES_NOT_LAUNCHED = 2,
	
	ERR_MAX
} t_error;

typedef struct s_prgm_options {
	BOOL verbose; /* Default: NO */
	
	NSUInteger x_size; /* Default, 0 (not checked) */
	NSUInteger y_size; /* Default, 0 (not checked) */
	CGFloat ratio; /* Default: 1; if negative, means not checked */
	
	BOOL check_embed;          /* Default: NO */
	
	BOOL check_all;            /* Default: NO */
	const char *output_format; /* Default: "\"%t — %a — %s\" does not fulfill the conditions" */
	BOOL always_yes;           /* Default: YES */
} t_prgm_options;

#endif /* !check_itunes_artworks_constants_h */
