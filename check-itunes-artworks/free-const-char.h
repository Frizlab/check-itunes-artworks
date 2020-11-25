/*
 *  free_const_char.h
 *  check-itunes-artworks
 *
 *  Created by François LAMBOLEY on 6/20/12.
 *  Copyright 2011 Frost Land. All rights reserved.
 *
 *  Allow to easily free const char* variables without warning nor cast.
 */

#ifndef FREE_CONST_CHAR_H_
# define FREE_CONST_CHAR_H_

# include <stdlib.h>

union u_const_vs_no_const_char
{
	char *not_consted_char;
	const char *consted_char;
};

static void free_const_char(const char	*str)
{
	union u_const_vs_no_const_char u;
	
	u.consted_char = str;
	free(u.not_consted_char);
}

#endif /* !FREE_CONST_CHAR_H_ */
