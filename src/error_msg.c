/* Error message printing. */

#include <stdarg.h>

#include "error_msg.h"

#ifdef HEADER
#include <stdio.h>
#include <errno.h>
#include <string.h>
#define HERE __FILE__, __LINE__
#endif /* HEADER */
#include <stdlib.h>

/* The name of the program running and of the source file the program
   is reading from.  The default values are just for debugging. */

const char * program_name = "PROGRAM NAME UNDEFINED";
const char * source_name = "SOURCE NAME UNDEFINED";
int * source_line = NULL;

/* Macro for repeated varargs printing things below. */

#define DO_PRINT(file)                          \
    va_start (a, format);                       \
    vfprintf (file, format, a);                 \
    fprintf (file, ".\n");                      \
    va_end (a)


/* Print a warning message with a line number.  */

void PRINT_FORMAT(2,3)
lwarning (unsigned line_number, const char * format, ...)
{
    va_list a;

    fprintf (stderr, "%s:%u: warning: ", source_name, line_number);

    DO_PRINT (stderr);
}

/* Print an error message for a specified line and then exit */

NO_RETURN PRINT_FORMAT(1,2)
line_error (const char * format, ... )
{
    va_list a;

    fprintf (stderr, "%s:%u: error: ", source_name, * source_line);

    DO_PRINT (stderr);

    exit (EXIT_FAILURE);
}

/* Print a warning message with a line number.  */

void PRINT_FORMAT(1,2)
line_warning (const char * format, ... )
{
    va_list a;

    fprintf (stderr, "%s:%u: warning: ", source_name, * source_line);

    DO_PRINT (stderr);
}

/* Print an information message with a line number.  */

void PRINT_FORMAT(1,2)
    line_info (const char * format, ... )
{
    va_list a;

    fprintf (stdout, "%s:%u: ", source_name, * source_line);

    DO_PRINT (stdout);
}

/* Print an error message for a specified line and then exit */

NO_RETURN PRINT_FORMAT(2,3)
    lerror ( unsigned line_number, const char * format, ... )
{
    va_list a;

    fprintf ( stderr, "%s:%u: error: ", source_name, line_number );

    DO_PRINT (stderr);

    exit (EXIT_FAILURE);
}

/* Print the specified error message and exit. */

NO_RETURN PRINT_FORMAT(1,2)
error (const char * format, ... )
{
    va_list a;

    fprintf ( stderr, "%s: error: ", program_name );

    DO_PRINT (stderr);

    exit (EXIT_FAILURE);
}

/* Print a warning message. */

void PRINT_FORMAT(1,2)
warning (const char * format, ... )
{
    va_list a;

    fprintf ( stderr, "%s: warning: ", program_name );
  
    DO_PRINT (stderr);
}

/* Print an internal error message.  This is for the case that
   something that should never happen occurs, such as a `default:' in
   a switch statement that is used to catch errors. */

NO_RETURN  PRINT_FORMAT(3,4)
bug (const char * file, unsigned line, const char * format, ... )
{
    va_list a;

    fprintf ( stderr, "%s:%s:%u: internal error: ", 
              program_name, file, line );
    fprintf ( stderr, "%s:%s:%u: internal error: ", 
              program_name, file, line );

    DO_PRINT (stderr);

    exit (EXIT_FAILURE);
}

