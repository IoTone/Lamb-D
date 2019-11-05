#!/bin/sh
# Assumes gdc, gcc, and a linux environment
# Actual results may vary.
mkdir -p lib
echo "If you need to, copy your c/c++ libs into the lib dir and re-run this script"
cd lib

# User: You should copy any libraries you need into lib
# TODO: Add a decent way to automate this.  For now, leave it up to the user
# to copy lib files into lib
# NOTE: We don't need to package this stuff if we compile with --static
# cp /lib/x86_64-linux-gnu/libgcc_s.so.1 .
# cp /lib/x86_64-linux-gnu/libc.so.6 .
# cp /usr/lib/x86_64-linux-gnu/libatomic.so.1 .
# cp /lib/x86_64-linux-gnu/librt.so.1 .
# cp /lib/x86_64-linux-gnu/libm.so.6 .
# cp /lib/x86_64-linux-gnu/libpthread.so.0 .
# cp /lib/x86_64-linux-gnu/libdl.so.2 .
# cp ../openssl-1.1.0l/*.a .

cd ..
# Copy the binary into bin
mkdir -p bin
cp lamb-d bin
chmod 755 bin/lamb-d
# Create a new bootstrap from the template
# Presumably we might need to generate something in this template
# but for now just copy it
cp bootstrap_tpl.sh bootstrap
chmod 755 bootstrap
zip -yr lambda.zip bootstrap bin lib
