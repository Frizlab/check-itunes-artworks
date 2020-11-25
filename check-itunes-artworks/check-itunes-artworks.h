/*
 * check-itunes-artworks.h
 * check-itunes-artworks
 *
 * Created by François LAMBOLEY on 6/21/12.
 * Copyright (c) 2012 Frost Land. All rights reserved.
 */

#ifndef check_itunes_artworks_check_itunes_artworks_h
# define check_itunes_artworks_check_itunes_artworks_h

# include "constants.h"

static inline BOOL has_correct_ratio(NSUInteger x, NSUInteger y, CGFloat test_ratio) {
	return ABS((CGFloat)x / (CGFloat)y - test_ratio) <= MAX_DIFF_FOR_DOUBLE_EQUALITY;
}

t_error check_selected_artworks(const t_prgm_options *options);

#endif
