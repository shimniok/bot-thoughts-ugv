/*********************************************************************

MODULE NAME:    b64.c

AUTHOR:         Bob Trower 08/04/01, Michael Shimniok 04/04/13

COPYRIGHT:      Copyright (c) Trantor Standard Systems Inc., 2001

NOTES:          This source code may be used as you wish, subject to
                the MIT license.  See the LICENCE section below.

                Canonical source should be at:
                    http://base64.sourceforge.net

DESCRIPTION:    Implements Base64 Content-Transfer-Encoding standard
                described in RFC1113 (http://www.faqs.org/rfcs/rfc1113.html).

                Groups of 3 binary bytes from a binary stream are coded as
                groups of 4 printable bytes in a text stream.
*********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "b64.h"

/**
 * Translation Table as described in RFC1113
 */
static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/**
 * Translation Table to decode (created by author)
 */
//static const char cd64[]="|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

/**
 * returnable errors
 *
 * Error codes returned to the operating system.
 *
 */
#define B64_SYNTAX_ERROR        1
#define B64_FILE_ERROR          2
#define B64_FILE_IO_ERROR       3
#define B64_ERROR_OUT_CLOSE     4
#define B64_LINE_SIZE_TO_MIN    5
#define B64_SYNTAX_TOOMANYARGS  6

/**
 * encodeblock
 *
 * encode 3 8-bit binary bytes as 4 '6-bit' characters
 */
void encodeblock( const unsigned char *in, unsigned char *out, const int len )
{
    out[0] = (unsigned char) cb64[ (int)(in[0] >> 2) ];
    out[1] = (unsigned char) cb64[ (int)(((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4)) ];
    out[2] = (unsigned char) (len > 1 ? cb64[ (int)(((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6)) ] : '=');
    out[3] = (unsigned char) (len > 2 ? cb64[ (int)(in[2] & 0x3f) ] : '=');
}

/**
 * encodeblock
 *
 * encode a buffer of binary data into lines of '6-bit' characters
 */
int encode( const unsigned char *sin, const int length, unsigned char *sout, const int linesize )
{
    unsigned char in[3];
    int i;
    int j; // j is the sin position index
    int len, blocksout = 0;
    int retcode = 0;

    in[0] = 0;
    j = 0;
    while( j < length ) {
        // Get a block of three bytes to encode
        // If there's < 3 bytes left in the string,
        // pad with '\0'
        len = 0;
        for (i=0; i < 3; i++, j++) {
            if (j < length) {
                len++;
                in[i] = sin[j];
            } else {
                in[i] = '\0';
            }
        }
        //printf("2. in=%02x %02x %02x j=%u length=%u\n", in[0], in[1], in[2], j, length);
        encodeblock( in, sout, len );
        //printf("4. sout=%c%c%c%c\n", sout[0], sout[1], sout[2], sout[3]);
        sout += 4;
        blocksout++;
        if( linesize && blocksout >= (linesize/4) ) {
            *sout++ = '\n';
            blocksout = 0;
        }
    }
    *sout = '\0';
    return( retcode );
}

/******************************************************************************
LICENCE:        Copyright (c) 2001 Bob Trower, Trantor Standard Systems Inc.

                Permission is hereby granted, free of charge, to any person
                obtaining a copy of this software and associated
                documentation files (the "Software"), to deal in the
                Software without restriction, including without limitation
                the rights to use, copy, modify, merge, publish, distribute,
                sublicense, and/or sell copies of the Software, and to
                permit persons to whom the Software is furnished to do so,
                subject to the following conditions:

                The above copyright notice and this permission notice shall
                be included in all copies or substantial portions of the
                Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
                KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
                WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
                PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
                OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
                OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
                SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

VERSION HISTORY:
                Bob Trower 08/04/01 -- Create Version 0.00.00B
                Bob Trower 08/17/01 -- Correct documentation, messages.
                                    -- Correct help for linesize syntax.
                                    -- Force error on too many arguments.
                Bob Trower 08/19/01 -- Add sourceforge.net reference to
                                       help screen prior to release.
                Bob Trower 10/22/04 -- Cosmetics for package/release.
                Bob Trower 02/28/08 -- More Cosmetics for package/release.
                Bob Trower 02/14/11 -- Cast altered to fix warning in VS6.

*****************************************************************************/
