#!/bin/sh
#
# Create new user and add their SSH public key

# Help info
if [ "$1" = "-h" ]; then

	echo
	echo "Usage: add-ssh-user.sh <no arguments>"
	echo
	echo "Create a new user and add their SSH public key to their"
	echo "authorized_keys file. Script will prompt for two inputs:"
	echo
	echo "  1) Username"
	echo "  2) Filename of SSH public key"
	echo
	echo "The SSH public key will be converted to openssh format if"
	echo "possible. Script must be executed as root (sudo)."
	echo

	exit 0

fi

# must be root or sudoer
if [ "$(whoami)" != "root" ]; then
	echo "Try running this script with sudo: \"sudo ./new-ssh-user.sh\""
	exit 1
fi

while [ -z "$user" ]; do
	read -e -p "User name: " user
done

while [ ! -f "$importkeyfile" ]; do
	read -e -p "SSH public key file: " importkeyfile
done

# define user name
userssh="/home/$user/.ssh"
userkeyfile="$userssh/authorized_keys"

# Create the user
useradd "$user"

# Create user's .ssh directory, give user ownership and apply permissions
mkdir "$userssh"
chown "$user" "$userssh"
chmod 700 "$userssh"

# Import key
importkey_check=`ssh-keygen -l -f "$importkeyfile"`
if [ "$importkey_check" != "$importkeyfile is not a public key file." ]; then
	cat "$importkeyfile" >> "$userkeyfile"
else

	# importkeyfile may require conversion
	convertedkey="$userssh/tempkey.pub"
	ssh-keygen -i -f "$importkeyfile" >> "$convertedkey"
	converted_check=`ssh-keygen -l -f "$convertedkey"`

	# Check if converted key is a valid public key
	if [ "$converted_check" != "$convertedkey is not a public key file." ]; then
		cat "$convertedkey" >> "$userkeyfile"
	else
		echo "$importkeyfile cannot be converted into a valid public key"
		exit 1
	fi

	# remove converted key
	rm "$convertedkey"

fi

# Set permissions on key file
chmod 600 "$userkeyfile"

echo "User generated and public key imported"
