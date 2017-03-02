#!/bin/bash

# define aur helper and ver
aur_helper="apacman"
aur_helper_version="3.1-1"

# install aur helper from github and then install app using helper
if [[ ! -z "${aur_packages}" ]]; then

	pacman -S --needed base-devel --noconfirm
	curl -o "/tmp/${aur_helper}-any.pkg.tar.xz" -L "https://github.com/binhex/arch-packages/raw/master/compiled/${aur_helper}-${aur_helper_version}-any.pkg.tar.xz"
	pacman -U "/tmp/${aur_helper}-any.pkg.tar.xz" --noconfirm
	
	# unset failing build on non zero exit code (required as apacman can have exit code of 1 if systemd ref in install)
	set +e

	# check aur helper is functional and then use
	"${aur_helper}" -V
	helper_check_exit_code=$?

	"${aur_helper}" -S ${aur_packages} --noconfirm
	helper_package_exit_code=$?

	# reset flag to force failed build on non zero exit code
	set -e

	if (( ${helper_check_exit_code} != 0 )); then
		echo "${aur_helper} check returned exit code ${helper_check_exit_code}, exiting script..."
		return 1
	fi

	if (( ${helper_package_exit_code} != 0 && ${helper_package_exit_code} != 1 )); then
	
		echo "${aur_helper} returned exit code ${helper_package_exit_code} (exit code 1 ignored), showing man for exit codes:-"
		echo "0   Success"
		echo "1   Miscellaneous errors"
		echo "2   Invalid parameters"
		echo "3   Fatal errors, not warnings"
		echo "4   No package matches found"
		echo "5   Package does not exist"
		echo "6   No internet connection"
		echo "7   No free space in tmpfs"
		echo "8   One or more package(s) failed to build, keep going"
		echo "9   One package failed to build, do not continue"
		echo "10  Permission problem −− fakeroot"
		echo "11  Permission problem −− root user"
		echo "12  Permission problem −− sudo"
		echo "13  Permission problem −− su"

		# set return code to 1 to denote failure to build env
		return 1
	fi

	# remove base devel excluding useful core packages
	pacman -Ru $(pacman -Qgq base-devel | grep -v pacman | grep -v sed | grep -v grep | grep -v gzip) --noconfirm

	# remove cached aur packages
	rm -rf "/var/cache/${aur_helper}/" || true

else

	return 0

fi
