#!/bin/sh
cd source
wget https://raw.githubusercontent.com/adamdruppe/arsd/master/http2.d
cd ..
wget https://github.com/adamdruppe/arsd/blob/master/LICENSE -O LICENSE.arsd

wget https://www.openssl.org/source/openssl-1.1.0l.tar.gz
tar -xvf openssl-1.1.0l.tar.gz
openssl-1.1.0l/
./config -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)'
make
cd ..
