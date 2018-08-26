#!/bin/bash

#
#  Build script to build libbash.sh debian package
#
#  Project: https://github.com/pruje/libbash.sh
#  MIT License
#  Copyright (c) 2017 Jean Prunneaux
#


# get current_directory
current_directory=$(dirname "$0")

# test if libbash is there
if ! [ -d "$current_directory/libbash.sh" ] ; then
	echo "ERROR: you must put sources in the libbash.sh directory!"
	exit 1
fi

# get time2backup version
version=$(grep "lb_version=" "$current_directory/libbash.sh/libbash.sh" | head -1 | cut -d= -f2)
if [ -z "$version" ] ; then
	echo "ERROR: Cannot get libbash version!"
	exit 1
fi

echo -n "Build debian package for libbash v$version? (y/N) "
read confirm
if [ "$confirm" != "y" ] ; then
	exit
fi

echo

# create build environment
mkdir -p "$current_directory/build"
if [ $? != 0 ] ; then
	echo "ERROR while creating build directory. Please verify your access rights."
	exit 3
fi

package="$current_directory/build/package"
install_path="$package/usr/lib/libbash"

# clean and copy package files
echo "Clean and copy package..."
rm -rf "$package" && cp -rp "$current_directory/package" "$current_directory/build/"
if [ $? != 0 ] ; then
	echo "ERROR while copying package files. Please verify your access rights."
	exit 3
fi

echo "Set version number..."
sed -i "s/^Version: .*/Version: $version/" "$package/DEBIAN/control"
if [ $? != 0 ] ; then
	echo "ERROR while setting the package version number."
	exit 4
fi

echo "Copy libbash sources..."

# create directories
mkdir -p "$install_path/locales"
if [ $? != 0 ] ; then
	echo "ERROR while copying sources files. Please verify your access rights."
	exit 5
fi

# copy libbash main files
for f in libbash.sh libbash_gui.sh docs README.md LICENSE.md ; do
	cp -r "$current_directory/libbash.sh/$f" "$install_path"
	if [ $? != 0 ] ; then
		echo "ERROR while copying sources files. Please verify your access rights."
		exit 5
	fi
done

# copy locales
for f in "$current_directory/libbash.sh/locales"/*.sh ; do
	cp "$f" "$install_path/locales/"
	if [ $? != 0 ] ; then
		echo "ERROR while copying sources files. Please verify your access rights."
		exit 5
	fi
done

echo "Set permissions..."
chmod -R 755 "$install_path" && \
chmod 644 "$install_path"/*.md "$install_path"/docs/* && \
sudo chown -R root:root "$install_path"
if [ $? != 0 ] ; then
	echo "... Failed!"
	exit 6
fi

# go into the build directory
cd "$current_directory/build"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to go into the build directory!"
	exit 7
fi

# set archive name
archive="libbash.sh_$version.deb"

echo "Generating deb package..."

dpkg-deb --build package $archive
if [ $? != 0 ] ; then
	echo "...Failed!"
	exit 8
fi

# create archive directory
mkdir -p "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Cannot create archive directory!"
	exit 9
fi

# move archive above
mv "$archive" "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to move the archive!"
	exit 9
fi

# going up
cd "$version"
if [ $? != 0 ] ; then
	echo "ERROR: Failed to go into the archive directory!"
	exit 7
fi

echo "Generating checksum..."
sha256sum $archive > sha256sum.txt
if [ $? != 0 ] ; then
	echo "...Failed!"
	exit 10
fi

echo "Clean files..."
sudo rm -rf ../package

echo
echo "Package is ready!"
