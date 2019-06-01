#!/bin/sh
#
# Copyright (c) 2010-2014 Sebastian Siebert (freespacer@gmx.de)
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# supported os
SUSE_LIST="SLE10-IA32 \
SLE10-AMD64 \
SLE11-IA32 \
SLE11-AMD64 \
SLE12-AMD64 \
SUSE121-IA32 \
SUSE121-AMD64 \
SUSE122-IA32 \
SUSE122-AMD64 \
SUSE123-IA32 \
SUSE123-AMD64 \
SUSE131-IA32 \
SUSE131-AMD64 \
SUSE132-IA32 \
SUSE132-AMD64 \
SUSE-autodetection"

# unsupported os (unofficial package list)
# unlock this list with, for example:
# UNSUPPORTED="yes" ./ati-driver-installer-<version>-<architecture>.run --buildpkg SuSE/SUSE114-AMD64
if [ "${UNSUPPORTED}" = "yes" -o "${UNSUPPORTED}" = "true" -o "${UNSUPPORTED}" = "1"  ]; then
    SUSE_LIST="${SUSE_LIST} SUSE114-IA32 SUSE114-AMD64 SUSETUMBLEWEED-IA32 SUSETUMBLEWEED-AMD64 SUSEFACTORY-IA32 SUSEFACTORY-AMD64"
fi
