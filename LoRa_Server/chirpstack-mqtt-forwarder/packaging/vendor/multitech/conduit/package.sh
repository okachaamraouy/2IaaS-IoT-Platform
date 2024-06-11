#!/usr/bin/env bash

set -e

REV="r1"

PACKAGE_NAME=`cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"`
PACKAGE_VERSION=`cargo metadata --no-deps --format-version 1| jq -r ".packages[0].version"`
PACKAGE_DESCRIPTION=`cargo metadata --no-deps --format-version 1| jq -r ".packages[0].description"`
BIN_PATH="../../../../target/armv5te-unknown-linux-musleabi/release/${PACKAGE_NAME}"
DIR=`dirname $0`
PACKAGE_DIR="${DIR}/package"

# Cleanup
rm -rf $PACKAGE_DIR

# CONTROL
mkdir -p $PACKAGE_DIR/CONTROL
cat > $PACKAGE_DIR/CONTROL/control << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION-$REV
Architecture: arm926ejste
Maintainer: Orne Brocaar <info@brocaar.com>
Priority: optional
Section: network
Source: N/A
Description: $PACKAGE_DESCRIPTION
EOF

cat > $PACKAGE_DIR/CONTROL/postinst << EOF
sed -i "s/ENABLED=.*/ENABLED=\"yes\"/" /etc/default/monit
update-rc.d monit defaults
/etc/init.d/monit start
/usr/bin/monit reload
EOF
chmod 755 $PACKAGE_DIR/CONTROL/postinst

cat > $PACKAGE_DIR/CONTROL/prerm << EOF
/etc/init.d/$PACKAGE_NAME-ap1 stop
/etc/init.d/$PACKAGE_NAME-ap2 stop
EOF
chmod 755 $PACKAGE_DIR/CONTROL/prerm

cat > $PACKAGE_DIR/CONTROL/conffiles << EOF
/var/config/$PACKAGE_NAME/ap1/$PACKAGE_NAME.toml
/var/config/$PACKAGE_NAME/ap2/$PACKAGE_NAME.toml
EOF

# Files
mkdir -p $PACKAGE_DIR/opt/$PACKAGE_NAME
mkdir -p $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap1/examples
mkdir -p $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap2/examples
mkdir -p $PACKAGE_DIR/etc/monit.d
mkdir -p $PACKAGE_DIR/etc/init.d

cp files/ap1/$PACKAGE_NAME-ap1.init $PACKAGE_DIR/etc/init.d/$PACKAGE_NAME-ap1
cp files/ap2/$PACKAGE_NAME-ap2.init $PACKAGE_DIR/etc/init.d/$PACKAGE_NAME-ap2

cp files/ap1/$PACKAGE_NAME-ap1.monit $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap1/examples/$PACKAGE_NAME-ap1.monit
cp files/ap2/$PACKAGE_NAME-ap2.monit $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap2/examples/$PACKAGE_NAME-ap2.monit

cp files/ap1/$PACKAGE_NAME.toml $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap1
cp files/ap2/$PACKAGE_NAME.toml $PACKAGE_DIR/var/config/$PACKAGE_NAME/ap2

cp $BIN_PATH $PACKAGE_DIR/opt/$PACKAGE_NAME/$PACKAGE_NAME

# Package
opkg-build -o root -g root $PACKAGE_DIR

# Cleanup
rm -rf $PACKAGE_DIR
