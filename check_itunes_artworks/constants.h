/*
 * constants.h
 * check_itunes_artworks
 *
 * Created by François LAMBOLEY on 6/18/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#ifndef check_itunes_artworks_constants_h
#define check_itunes_artworks_constants_h

typedef enum e_error {
	ERR_NO_ERR = 0,
	ERR_SYNTAX = 1,
	ERR_ITUNES_NOT_LAUNCHED = 2,
	
	ERR_MAX
} t_error;


#endif /* !check_itunes_artworks_constants_h */
