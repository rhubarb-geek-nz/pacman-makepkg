# rhubarb-geek-nz/pacman-makepkg

The official documentation for building packages recommends using a chroot environment. There are also various example around for using Docker to perform this task.

The major advantage of using Docker is that you don't actually need to manage and maintain an ArchLinux environment for building the packages, you can create the Docker on the fly as needed and dispose.

This contains a pair of Dockerfiles, one for x86_64, the other for armv7/aarch64.

You can happily run the ARM docker images on a Raspberry PI.

The steps take in the Dockerfile are:

- create a base-devel environment suitable for the output
- restore the Locale that is stripped from the Docker images
- add the required base packages
- add a private pacman repository
- set up the entry script as package.sh

When it comes to run time, it is invoked as follows

~~~
(
	cat <<EOF
keygrip-value
keyid-value
password-value
packager-value
EOF
	cat "$KEYFILE"
) | docker run -i -v $(pwd):/mnt --rm archlinux-makepkg
~~~

The arguments are as follows

- -i allow stdin to be passed through to the underlying script
- -v mount with the current working directory as /mnt
- --rm remove the instance once completed

The variables are then piped through in the order required by the package.sh

The package.sh then does the following

- when it starts it will run as root, 
    - run the depends.sh as packager to get the dependencies from PKGBUILD
    - add dependencies while root
    - invoke the same script as a lower privileged user to perform the actual build
- invoked as non-root it will
    -  read the arguments to determine GPG key to use to sign and the name of the packager.
    - it copies the PKGBUILD script from /mnt to the home directory
    - performs the build and sign
    - once that has completed copy the output package to the /mnt directory

The dependencies should be inferred from the PKGBUILD file. 

The signature key and credentials are provided build time, stdin is used to the PKGBUILD script has no access to the keyfile. The packager user does not have sudo access, so the depends.sh is run as packager as an initial step.

The output packages will be returned to the current directory before the docker container deletes itself

It is a good idea to always build from a fresh image and not reuse a container so you can be sure each is a clean build
