/* Do tag table stuff for Cfunctions. */

/* 
   This file is part of Cfunctions.

   Copyright (C) 1998, 2009  Ben K. Bullock

   Cfunctions is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   Cfunctions is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Cfunctions; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdlib.h>
#include <string.h>
#include "error_msg.h"
#include "sys_or_exit.h"
#include "tags.h"
#include "c-word.h"
#include "wt.h"

#ifdef HEADER

enum tag_type
{
  TAG_FUNCTION,

  /* Any of `struct', `union' or `enum' names will be preceeded by the
     appropriate keyword so they can all be put into one category. */

  TAG_STRUCT_UNION_ENUM,
  TAG_MACRO,
  TAG_ENUM_VAL,
  TAG_TYPEDEF,
  TAG_GLOBAL,
  N_TAG_TYPES
};

#endif /* HEADER */

const char * tag_type_name [ N_TAG_TYPES ] =
{
  "function",
  "struct, union or enum",
  "macro",
  "enum_val",
  "typedef",
  "global"
};

extern int yylineno;
extern unsigned seen_extern;

/* File to write tag table to. */

static FILE * tag_file;
static const char * tag_file_name = "CFTAGS";
static int tags; /* -t option */

#ifdef CFUNCTIONS_DEBUG
int tag_debug;
#endif /* CFUNCTIONS_DEBUG */

/* 
   Output an entry for a new file.
*/

void
tag_new_file (const char * file_name)
{
  static const char * current_file = "undefined";

  if ( ! tags )
    return;

  if (strcmp (current_file, file_name))
    fprintf (tag_file, "\f\n%s\n", file_name);

  current_file = file_name;
}

/* 
   Make a tag.  The input tag may have all kinds of trailing things.
   This removes the trailing junk.
*/

void 
tag_make (unsigned char * tag, enum tag_type t, unsigned line)
{
  unsigned i, l;
  unsigned char * tidy_tag;

#ifdef CFUNCTIONS_DEBUG

  /* This is a debugging feature independent of whether Cfunctions is
     making a TAGS file.  If a C keyword gets to here, then there
     was a misunderstanding by Cfunctions. */

  i = c_word ( tag );
  tidy_tag = malloc_or_exit ( i+1 );
  strncpy ((char *) tidy_tag, (char *) tag, i);
  tidy_tag[i] = '\0';

  /* If the requested tag is a C keyword, then Cfunctions has made a
     misunderstanding. */

  if (warns.reserved_words)
    if ( is_keyword ( tidy_tag ) != -1 )
      line_warning ("tag `%s' is a GNU C reserved word", tidy_tag);

  #endif /* CFUNCTIONS_DEBUG */

  if ( ! tags )
    {
      #ifdef CFUNCTIONS_DEBUG
      free (tidy_tag);
      #endif
      return;
    }
  l = strlen ((char *)tag);

  /* Sometimes `yylineno' is too big, because of extra `\n' characters
     which are included in the trailing part of yytext. */

  for (i = 0; i < l; i++)
    if (tag[i] == '\n')
      line--;

  #ifdef CFUNCTIONS_DEBUG

  /* This prints the line numbers in a C file in the Gnu coding
     standards error reporting format so that one can easily search
     for matching tags lines in the original C file using Emacs's
     `compile-mode' */

  if ( tag_debug )
    printf ( "%s:%u: saving tag `%s' of type `%s'.\n", 
             source_name, line, tidy_tag, tag_type_name[t] );
  #else

  i = c_word ( tag );
  tidy_tag = malloc_or_exit ( i+1 );
  strncpy (tidy_tag, tag, i);
  tidy_tag[i] = '\0';

  #endif

  fprintf (tag_file, "%d:%s,%d\n", line, tidy_tag, t );
  free (tidy_tag);
}

void
tag_init (void)
{
  tag_file = fopen_or_exit ( tag_file_name, "w" );
  tags = 1;
}

void
tag_exit (void)
{
  if (tag_file)
    fclose (tag_file);
}