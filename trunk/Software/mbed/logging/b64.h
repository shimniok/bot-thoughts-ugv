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

#ifndef __B64_H
#define __B64_H

/**
 * encodeblock
 *
 * encode 3 8-bit binary bytes as 4 '6-bit' characters
 */
void encodeblock( const unsigned char *in, unsigned char *out, const int len );

/**
 * encode
 *
 * encode a buffer of binary data into lines of '6-bit' characters
 */
int encode( const unsigned char *sin, const int length, unsigned char *sout, const int linesize );

#endif

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
