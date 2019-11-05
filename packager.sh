#!/bin/sh
# Assumes gdc, gcc, and a linux environment
# Actual results may vary.
mkdir -p lib
echo "If you need to, copy your c/c++ libs into the lib dir and re-run this script"
cd lib

# User: You should copy any libraries you need into lib
# TODO: Add a decent way to automate this.  For now, leave it up to the user
# to copy lib files into lib

# cp /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 .
# /lib/x86_64-linux-gnu/ld-2.23.so .

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
