#!/bin/bash

#
#  Build script for time2backup debian package
#
#  Project: https://github.com/pruje/libbash.sh
#  MIT License
#  Copyright (c) 2017 Jean Prunneaux
#


# get current_directory
current_directory=$(dirname "$0")

# test if time2backup is there
if ! [ -d "$current_directory/libbash" ] ; then
	echo "ERROR: you must put libbash sources in the libbash directory!"
	exit 1
fi

# get time2backup version
version=$(grep "^lb_version=" "$current_directory/libbash/libbash.sh" | head -1 | cut -d= -f2)
if [ -z "$version" ] ; then
	echo "ERROR: Cannot get libbash version!"
	exit 1
fi

# create build environment
mkdir -p "$current_directory/build"
if [ $? != 0 ] ; then
	echo "ERROR while creating build directory. Please verify your access rights."
	exit 1
fi

package="$current_directory/build/package"
install_path="$package/usr/lib/libbash"

# clear and copy package files
echo "Copy package..."
rm -rf "$package" && cp -rp "$current_directory/package" "$current_directory/build/"
if [ $? != 0 ] ; then
	echo "ERROR while copying package files. Please verify your access rights."
	exit 1
fi

echo "Set version number..."
sed -i "s/^Version: .*/Version: $version/" "$package/DEBIAN/control"
if [ $? != 0 ] ; then
	echo "ERROR while copying package files. Please verify your access rights."
	exit 1
fi

echo "Copy libbash sources..."

mkdir -p "$install_path"
if [ $? != 0 ] ; then
	echo "ERROR while copying sources files. Please verify your access rights."
	exit 1
fi

# copy only useful files
for f in libbash.sh libbash_gui.sh locales ; do
	cp -r "$current_directory/libbash/$f" "$install_path"
	if [ $? != 0 ] ; then
		echo "ERROR while copying sources files. Please verify your access rights."
		exit 1
	fi
done

echo "Set permissions..."
sudo chown -R root:root "$install_path" && sudo chmod -R 755 "$install_path"

# go into the build directory
cd "$current_directory/build"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to go into the build directory!"
	exit 4
fi

# set archive name
archive="libbash.sh_$version.deb"

echo
echo "Generating deb package..."

dpkg-deb --build package $archive
if [ $? != 0 ] ; then
	echo "...Failed!"
	exit 5
fi

# create archive directory
mkdir -p "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Cannot create archive directory!"
	exit 1
fi

# move archive above
mv "$archive" "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to move the archive!"
	exit 1
fi

# going up
cd "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to go into the archive directory!"
	exit 4
fi

echo
echo "Generating checksums..."
sha256sum $archive > sha256sum.txt
if [ $? != 0 ] ; then
	echo "...Failed!"
	exit 6
fi

echo
echo "Clean files..."
sudo rm -rf ../package

echo
echo "Ready to deploy!"
