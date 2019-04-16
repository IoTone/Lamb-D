#!/bin/sh
# Assumes gdc, gcc, and a linux environment
# Actual results may vary.
mkdir -p lib
cd lib
cp /lib/x86_64-linux-gnu/libgcc_s.so.1 .
cp /lib/x86_64-linux-gnu/libc.so.6 .
cp /usr/lib/x86_64-linux-gnu/libatomic.so.1 .
cp /lib/x86_64-linux-gnu/librt.so.1 .
cp /lib/x86_64-linux-gnu/libm.so.6 .
cp /lib/x86_64-linux-gnu/libpthread.so.0 .
cp /lib/x86_64-linux-gnu/libdl.so.2 .
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
