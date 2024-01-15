#!/bin/sh -ex
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb-geek-nz/pacman-makepkg.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

MYID=$(id -u)
BUILDER=packager

if test $MYID = 0
then
	DEPENDS=

	for d in $( su - -c /depends.sh $BUILDER )
	do
		DEPENDS="$DEPENDS $d"
	done

	if test -n "$DEPENDS"
	then
		pacman -Sy --noconfirm $DEPENDS
	fi

	pacman -R --noconfirm rhubarb-pi-pacman
	su - -c "$0" $BUILDER
	cp /home/$BUILDER/*pkg.tar.* /mnt
else
	id

	read KEYGRIP
	read KEYID
	read PASSWORD
	read PACKAGER

	gpg --list-keys

	cat > .gnupg/gpg-agent.conf <<EOF
allow-preset-passphrase
default-cache-ttl 31536000
default-cache-ttl-ssh 31536000
max-cache-ttl 31536000
max-cache-ttl-ssh 31536000
debug-all
EOF

	gpg --batch --import

	gpg-connect-agent -v </dev/null

	/usr/lib/gnupg/gpg-preset-passphrase --verbose --preset "$KEYGRIP" <<EOF
$PASSWORD
EOF

	cp /mnt/PKGBUILD .

	PACKAGER="$PACKAGER" makepkg --sign --key "$KEYID"
fi
