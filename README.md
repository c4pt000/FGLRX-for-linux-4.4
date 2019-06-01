
<br>
./ati-install.sh 15.302 --install
<br>
<br>
<br>
scl enable devtoolset-6 bash
<br>
<br>
./ati-install.sh 15.302 --install
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>


ATI INSTALLER PACKAGING ENVIRONMENT AND POLICY LAYER

1. Target audience
2. Interface Versioning
 a. API Version 1
  i. Requirements
  ii. Optional
 b. API Version 2
  i. Requirements
  ii. Optional
 c. Notes
3. General notes on the packaging and policy layer environment
 a. Structure of the <installer root> directory (supported by ATI)
 b. Proposed distribution specification file naming convention (supported by a distribution vendor)
 c. ati-packager-helper.sh
 d. Custom distribution-specific settings folder
 e. ati-packager.sh parameter processing requirements
4. Package generation using ati-packager.sh
 a. --get-supported option
 b. --buildpkg option
 c. --buildprep option
 d. --installpkg option
 e. --installprep option
 f. --identify option
 g. --getAPIVersion option
5. Policy layer interface using ati-packager.sh
 a. --printpolicy option
 b. Additional requirements for the policy layer
  i. Version string requirements
  ii. Reliance on ati-installer.sh
 c. General notes on the policy layer
  i. Backward compatibility
  ii. Using check.sh for obtaining X version and architecture information
  iii. /etc/ati/inst_path_default and /etc/ati/inst_path_override
  iv. Environment variables supported by ati-installer.sh
 d. Policy interface example


1. Target audience
------------------
The target audience is distribution vendors that wish to use the packaging features or policy layer of the ATI Installer.



2. Interface Versioning
--------------------

2a. API Version 1 created 07/08/2005
------------------------------------

2ai. Requirements
-----------------
The requirements for Version 1 are:

   -All notes on the packaging and policy layer environment as described in Section 3
    should be followed, of particular importance are:
       Proposed file naming convention     - Referenced in section 3b.
       ati-packager-helper.sh              - Referenced in section 3c.
       parameter processing requirements   - Referenced in section 3e.

   -ati-packagers.sh must support the following options:
       --get-supported                     - Referenced in section 4a.
       --buildpkg                          - Referenced in section 4b.

2aii. Optional
--------------
Optional for Version 1:
   -Implementation of the Policy layer interface as Referenced in Section 5

   -Implementation of
          --getMaintainer                  - Referenced in section 4c.

2b. API Version 2 updated 03/19/2008
------------------------------------

2bi. Requirements
-----------------
In order to be Version 2 compliant the following must be implemented:

   -Complete Version 1 compliance          - Referenced in section 2a.

   -ati-packager.sh additionally must support the following options:
       --buildprep                         - Referenced in section 4d.
       --installpkg                        - Referenced in section 4e.
       --installprep                       - Referenced in section 4f.
       --identify                          - Referenced in section 4g.
       --getAPIVersion                     - Referenced in section 4h.

2bii. Optional
--------------
Optional for Version 2:
   -Implementation of the Policy layer interface as Referenced in Section 5
    has been modified in version 2.  While the policy layer is strongly
    encouraged, implementation remains optional

2c. Notes
---------
Note: parameters given in "[]" are optional and "<>" are mandatory



3. General notes on the packaging and policy layer environment
--------------------------------------------------------------

3a. Structure of the <installer root> directory (supported by ATI)
------------------------------------------------------------------
ati-installer.sh                     Main installer script
common                               Directory storing files common for all architectures and versions of X 
arch/*                               Directories storing files specific for each CPU architecture
x???[_64a]                           Directories storing files specific for each version of X
packages                             Directory storing distribution subdirectories
packages/<distro>/ati-packager.sh    Distribution specific packaging script
packages/<distro>/*                  Distribution specific files

Other files and directories are mostly Loki Setup related.

3b. Proposed distribution specification file naming convention (supported by a distribution vendor)
---------------------------------------------------------------------------------------------------
The suggested format for the generation of distribution specific package names is the following:
x???[_64a].<distro specific package name>.<distro specific spec file ext>

However, a distribution vendor is free to organize the distribution directory in any convenient manner,
as long as ati-packager.sh supports the interface and conventions described in this document.

Make sure the following requirements are met:
    - there is a unique distro specific package name for each x* directory and vice versa
    - distro specific package name does not contain whitespaces

3c. ati-packager-helper.sh
--------------------------
ati-packager-helper.sh resides in the same directory as ati-installer.sh and prints up-to-date 
information about the driver, depending on what is requested.

    --version           prints the driver version
    --release           prints the driver release
    --description       prints a description of the driver package
    --url               prints the driver home URL
    --vendor            prints ATI's corporation full name
    --summary           prints driver's summary information

This information can be used to update package specification files before package generation.

3d. Custom distribution-specific settings folder
------------------------------------------------
To allow easier maintenance and creation of ATI generable packages and
policies for the policy layer, /etc/ati/custom-package has been designated as a
valid package directory.  The installer will include this as a valid package only 
if the directory and the ati-packager.sh file inside the directory exist.  The 
user may override this path with their own folder by setting the environment variable
ATI_CUSTOM_PKG_DIR to the desired path.

3e. ati-packager.sh parameter processing requirements
-----------------------------------------------------
The parameters that ati-packager.sh should accept are described in the following sections.

If ati-packager.sh is passed a parameter it doesn't recognize (i.e. "ati-packager.sh --xyz"),
it must print the following on line:

${parameter}: unsupported option passed by ati-installer.sh

where ${parameter} is the unrecognized parameter ("--xyz" in the above example).



4. Package generation using ati-packager.sh
-------------------------------------------
The Installer (self-extracting archive) extracts files into the <installer root> directory (a subdirectory of 
the directory the archive was started from), changes path to this directory and then calls the ati-installer.sh script, 
passing one of the following parameters to it:
    --install                                               Causes Loki Setup to be called providing dialog based interface to
                                                            install the driver (either GTK based or ncurses)
    --help                                                  Prints a help message identifying usage
    --listpkg	                                          Lists all the generable packages for package generation, in the 
                                                            following format:
                                                                <distro1>/<package1>
                                                                <distro1>/<package2>
                                                                <distro2>/<package1>
                                                                . . .
    --buildpkg [<distro>/<package>] [--dryrun]              Builds the optionally specified distribution and package 
                                                            (Simulates the build if --dryrun is specified)
    --buildandinstallpkg [<distro>/<package>] [--dryrun]    Builds and Installs the optionally specified distribution 
                                                            (Simulates the build and install if --dryrun is specified)


4a. --get-supported option
--------------------------
For --listpkg, ati-installer.sh calls 
	packages/<distro>/ati-packager.sh --get-supported
and expects distribution generable packages to be listed to standard out, in the following format:
	<package>
	. . .

4b. --buildpkg option
---------------------
The --buildpkg option is intended to build a package for installation and should
perform as follows:
For --buildpkg [<distro>/<package>] and --buildandinstallpkg [<distro>/<package>],
ati-installer.sh calls packages/<distro>/ati-packager.sh --buildpkg <package>
ati-packager.sh is supposed to validate that the requested package is supported by
the distribution, build the requested package and return 0, or print an error
message to standard out otherwise and return 1.  Upon a successful build,
--buildpkg should create a file to house the name of the generated package(s).
The file should persist even if the installer is exited but remain in the same
folder.  It is suggested that the file be housed in the same directory as the
installation .run file and be given a meaningful name (e.g. tmpBuiltRedHatpkgs.txt
in the case of a RedHat package).  The --installpkg option should in turn remove
this created temporary file.

4c. --get-maintainer option
---------------------------
The --get-maintainer option is intended to communicate to ati-installer.sh
who are the current maintainers of packages/<distro>/ati-packager.sh
ati-installer.sh calls packages/<distro>/ati-packager.sh --get-maintainer 
when --listpkg is called. By default, if --get-maintainer is not implemented
ati-installer.sh will use the static defined maintainer in ati-installer.sh.

ati-installer.sh expects a ; delimited list of maintainers with the format 
"maintainer 1 <maintainer_1@group1.com>;maintainer 2 <maintainer_2@group2.com>;.."

4d. --buildprep option
----------------------
The --buildprep option is intended to ensure that prerequisites are installed on
the current system to build a package for installation and should behave as
follows:
For --buildpkg [<distro>/<package>] [--dryrun] and
--buildandinstallpkg [<distro>/<package>] [--dryrun], ati-installer.sh calls 
packages/<distro>/ati-packager.sh --buildprep <package> [--dryrun].
ati-packager.sh is supposed to validate that the requested package is supported
by the distribution and ensure that the second parameter is either --dryrun or
blank.  Ensure that prerequisite packages to a build a package for installation
are installed.  If it finds any requirements are not met, attempt to automatically
install or upgrade the required package.  If the system can not be made to meet
the requirements automatically, print a message detailing what is missing or needs
to be upgraded with instructions on how to complete the task and return 
${ATI_INSTALLER_ERR_PREP} (this variable has been exported for ati-packager.sh 
usage).  If the system meets all requirements return 0.  In the case of --dryrun
mode print informative messages to standard out, and return 0 for passes and return
${ATI_INSTALLER_ERR_PREP} for fails.

4e. --installpkg option
-----------------------
The --installpkg option is intended to install the package produced by --buildpkg
and should perform as follows:
For --buildandinstallpkg [<distro>/<package>], ati-installer.sh calls
packages/<distro>/ati-packager.sh --installpkg <package>.  ati-packager.sh is
supposed to validate that the requested package is supported by the distribution.
After ensuring that the expected file containing the name of the prebuilt package
exists (e.g.tmpBuiltRedHatpkgs.txt), attempt to install the package.  If the
installation is successful, print a message, return 0 and remove the file produced
by --buildpkg, else print a detailed error message and return 1.
 
4f. --installprep option
------------------------
The --installprep option is intended to ensure that prerequisites to run the driver
are installed on the current system and should behave as follows:
For --buildandinstallpkg [<distro>/<package>] [--dryrun], ati-installer.sh calls
packages/<distro>/ati-packager.sh --installprep <package> [--dryrun].
ati-packager.sh is supposed to validate that the requested package is supported by
the distribution, glibc is version 2.2 or higher, linux kernel is 2.6 or higher,
Xorg 6.7 or higher, and the following are all installed: libstdc++, libgcc,
fontconfig, freetype, zlib, gcc and mesa-libGL.  If any of those requirements are 
not met, attempt to automatically install or upgrade the required package.  If the
system can not be made to meet the requirements automatically, print a message 
detailing what is missing or needs to be upgraded with instructions on how to
complete the task and return ${ATI_INSTALLER_ERR_PREP}.  If the system meets all
requirements return 0.  In the case of --dryrun mode print informative messages to
standard out, and return 0 for passes and return ${ATI_INSTALLER_ERR_PREP} for fails.

4g. --identify option
---------------------
The --identify option is intended to communicate if a particular distro/version
is currently running and should perform as follows:
If the distribution and version that is currently running ati-packager.sh matches
the distribution that this ati-packager.sh script is intended for and the version
passed to it, then the script must return 0, else return ${ATI_INSTALLER_ERR_VERS}.
For example, running "packages/RedHat/ati-packager.sh --identify RHEL5" on a 32bit
Red Hat 5 system should return 0.  Where as running "packages/Ubuntu/ati-packager.sh
--identify gutsy" on a 32bit SuSE 10.3 system will return ${ATI_INSTALLER_ERR_VERS}.

4h. --getAPIVersion option
--------------------------
The --getAPIVersion option is intended to communicate to ati-installer.sh what
functionality is available to it by the corresponding ati-packager.sh and
should perform as follows:
For --buildpkg [<distro>/<package>] [--dryrun] and
--buildandinstallpkg [<distro>/<package>] [--dryrun], ati-installer.sh calls 
packages/<distro>/ati-packager.sh --getAPIVersion.  The top of this document
identifies the versioning requirements for the ati-packager.sh interface.  This
option should return the version number of the interface supported by its'
ati-packager.sh.  By default if --getAPIVersion is not implemented ati-installer.sh
will assume API version of 1 and disable any new functionality provided by API
version 2.

5. Policy layer interface using ati-packager.sh
-----------------------------------------------
Distribution maintainers are highly encouraged to implement an installation
policy for their distribution.  This can be done by implementing the following
function in their ati-packager.sh scripts:

5a. --printpolicy option
------------------------

    The ATI driver installer will invoke --printpolicy on a given
    ati-packager.sh script if it determines that it should be using that
    ati-packager.sh's policy.  If the installer runs all the ati-packager.sh
    scripts for the various distributions and finds exactly one that claims
    to match the current distribution, then it will call --printpolicy on that
    ati-packager.sh.  If the user sets the CURRENT_DISTRO to a valid
    distribution folder name (i.e. RedHat), then it will call --printpolicy on
    packages/${CURRENT_DISTRO}/ati-packager.sh.  If CURRENT_DISTRO is not set
    and no ati-packager.sh scripts claim to be the current distribution, then
    the default policy is used without modification (see below for how the
    default policy is normally used).

    When the ATI driver installer invokes --printpolicy, it also passes the
    VERSION string as provided by --getsupported (i.e. "./ati-packager.sh 
    --printpolicy VERSION").  The ati-packager.sh script should use the version 
    string to influence what policy it provides back to the ATI driver installer.

    --printpolicy must print a list of variables initializations (VAR=value) to
    standard out.  The list may include comments preceded by '#' and empty lines
    as needed.  The list must not include any commands, only variable
    initializations.

    The list of valid variables can be found in the output of
    "default_policy.sh --printpolicy".  The files that will be stored at the
    locations defined by these variables can be determined by examining the
    source paths that ati-installer.sh uses to copy the files into the locations
    described by the policy.

    Maintainers are free to define as many or as few of the variables defined in
    default_policy.sh as they wish.  Any variables not set by the distribution's
    policy will be set to the value described in default_policy.sh.

    --printpolicy must support every VERSION string that can be returned by the
    corresponding ati-packager's --getsupported option.  Maintainers may
    choose to support additional VERSION strings not returned by
    --getsupported for hidden functionality.  Such VERSION strings can be
    defined in the CURRENT_DISTRO_VERSION environment variable.  If that
    variable is set, the ATI installer will use its value as the VERSION string.

    If --printpolicy is passed a VERSION string it does not recognize, it must
    print "error: VERSION is not supported" followed by a new line, where
    VERSION is the unrecognized VERSION string.  It must also exit with return
    code 1.

5b. Additional requirements for the policy layer
------------------------------------------------

5bi. Version string requirements
--------------------------------

Any version string that --printpolicy supports must uniquely define the set of
environment variables that --printpolicy will return, regardless of what system
configuration is being used when --printpolicy is run.  For example, if
--identify returns a 0 when passed version string of "distro-v7-x700-x64" on a
64-bit system running Xorg 7.0.0, then --printpolicy "distro-v7-x700-x64" is run
on an ati-packager.sh script that supports the same policy interface version (v7
in this case; see below for more details on the policy interface version) on some
other system configuration (for example, 32-bit system running Xorg 6.8.0), the
script must return the same policy as it would if it would run on any other system.

Essentially what the above paragraph is saying is that all detection should go
on in --identify.  --printpolicy must not do any detection of any sort.
This makes it far easier to debug a system because the version string uniquely
identifies the policy that is being used for that installation.

Version strings must include the distribution name and policy interface version
number.  The policy interface version number is used to differentiate between
evolving implementations of the --identify and --printpolicy options.  Whenever
--identify or --printpolicy is changed such that the old implementations of these
options will no longer work with the values that the new options use, the policy
interface version must be incremented.

For an example of how to properly use version strings and policy interface
version numbers, see default_policy.sh.

5bii. Reliance on ati-installer.sh
----------------------------------

The --printpolicy and --identify options must not rely on being called
from ati-installer.sh.  For example, --printpolicy and --identify should
not depend on any environment variables that are present while ati-installer.sh
is being run but not present otherwise.  These options must be available outside
of invocation from ati-installer.sh so that a user can run ati-packager.sh from 
a normal shell to test the behaviour of the --printpolicy and --identify options.

5c. General notes on the policy layer
-------------------------------------

5ci. Backward compatibility
---------------------------

If distribution maintainers implement --printpolicy they must also implement 
--identify, however --identify can be implemented without --printpolicy.  If
maintainers choose not to implement these functions, they should be aware that
the default policy can change at any time, which may cause the installer to 
stop working correctly on a particular distribution.  The only way to guarantee
that the installer will continue to work on a given distribution is to ensure 
that all of the variables defined in default_policy.sh are overridden by the 
distribution's policy.

5cii. Using check.sh for obtaining X version, X layout and architecture information
-----------------------------------------------------------------------------------

To determine the X version and architecture of the current system, source the
check.sh script with the --noprint flag ("source ./check.sh --noprint").  This
will set the X_VERSION and _ARCH environment variables to coincide with the
X version and architecture of the current system.  X_VERSION is of the form
x{major}{minor}{point}[_64a].  For example, a 64-bit system with Xorg 7.0.0
would have an X_VERSION value of x690_64a, while a 32-bit system with Xorg
6.8.0 would have an X_VERSION value of x680.

X_LAYOUT will have the value of "modular" for Xorg 7.0 and above, and "monolithic" otherwise.
The install path variables are set based on X_LAYOUT.

_ARCH will be "x86_64" for 64-bit systems and "i?86" for 32-bit systems where
"?" is any single-digit integer (generally between 3 and 6).

5ciii. /etc/ati/inst_path_default and /etc/ati/inst_path_override
-----------------------------------------------------------------

All values set by the default policy, as well as the version of the driver being
installed and the time the file was created, are stored in
/etc/ati/inst_path_default.  This file will also contain an override for the
X_VERSION variable if the user specified the X_VERSION variable at install time.

The variables output by --printpolicy of the matching distribution and version
string are stored in /etc/ati/inst_path_override, along with the version of the
driver being installed and the time the file was created.  If no distributions
matched the current distribution, then /etc/ati/inst_path_override will still
contain the version of the driver being installed and the time the file was
created.  If the user specified the X_VERSION variable at install time, this
will also be present.  Comments will be added to inst_path_override in the
following cases:
 - user specified CURRENT_DISTRO at install time
 - user specified both CURRENT_DISTRO and CURRENT_DISTRO_VERSION at install time
 - user specified USE_DEFAULT_POLICY=1 at install time

To initialize the appropriate environment variables to the effective policy
being used, first source /etc/ati/inst_path_default and then source
/etc/ati/inst_path_override.

5civ. Environment variables supported by ati-installer.sh
---------------------------------------------------------

ati-installer.sh will use the values of the following environment variables if
they are specified at install time:

CURRENT_DISTRO - this must have a value equal to the name of one of the
    packages/* folder; it forces the installer to use a certain distribution and
    avoid detecting the distribution being used; if specified on its own,
    the policy version will still be detected

CURRENT_DISTRO_VERSION - defines the version string that the installer must use;
    setting this prevents the installer from doing any detection of the
    distribution or its version; CURRENT_DISTRO must be set to use this

USE_DEFAULT_POLICY - when this is set to 1, distribution detection will not be
    attempted and the installer will use only the default policy to define
    installation locations

X_VERSION - overrides the X version detected by the installer

5d. Policy interface example
----------------------------

The following code implements the policy interface for the Ubuntu distribution.
This code will report that the distribution matches if it is Ubuntu 5.10, Ubuntu 
6.06 or Ubuntu 7.10.  Otherwise it will report that the distribution does not match.
The policy that this code provides changes the location of the documentation
(${ATI_DOC}) depending on the version of Ubuntu being used.

To use this example, copy this code into the appropriate case statement of an
ati-packager.sh script.  The example is as follows:

--identify)

    DISTRO_VER=${2}

    case "${DISTRO_VER}" in

    breezy | 5.10)
        # compare with: Ubuntu 5.10 "Breezy Badger" \n \l
        echo -e Ubuntu 5.10 \"Breezy Badger\" \\\\n \\l\\n | diff /etc/issue - > /dev/null 2>&1
        RETVAL=$?

        ;;
    dapper | 6.06)
        # compare with: Ubuntu 6.06 LTS \n \l
        echo -e Ubuntu 6.06 LTS \\\\n \\l\\n | diff /etc/issue - > /dev/null 2>&1
        RETVAL=$?
  
        ;;

    gutsy | 7.10)
        #compare with : Ubuntu 7.10 \n \l
        echo -e Ubuntu 7.10  \\\\n \\l\\n | diff /etc/issue - > /dev/null 2>&1
        RETVAL=$?
        
        ;;
    *)
        #catch all for any erroneous input
        exit ${ATI_INSTALLER_ERR_VERS}

        ;;

    esac

    if [ ${RETVAL} -eq 0 ]
    then
        exit 0
    else
        exit ${ATI_INSTALLER_ERR_VERS}
    fi

    ;;
--printpolicy)
    DISTRO_VER=$2

    if [ "${DISTRO_VER}" == "breezy" -o "${DISTRO_VER}" == "dapper" ]
    then
        echo ATI_DOC=/usr/share/doc/ati-ubuntu-${DISTRO_VER}
    else
        echo "error: ${DISTRO_VER} is not supported"
        exit 1
    fi
    ;;

