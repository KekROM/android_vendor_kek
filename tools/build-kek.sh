#!/bin/bash
#
# build-kek.sh: the overarching build script for the ROM.
# Copyright (C) 2015 The PAC-ROM Project
# Copyright (C) 2015 KekROM Project
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

usage() {
    echo -e "${bldblu}Usage:${bldcya}"
    echo -e "  build-kek.sh [options] device"
    echo ""
    echo -e "${bldblu}  Options:${bldcya}"
    echo -e "    -c# Cleaning options before build:"
    echo -e "        1 - Run make clean"
    echo -e "        2 - Run make installclean"
    echo -e "    -d  Build rom without ccache"
    echo -e "    -e# Extra build output options:"
    echo -e "        1 - Verbose build output"
    echo -e "        2 - Quiet build output"
    echo -e "    -j# Set number of jobs"
    echo -e "    -k  Rewrite roomservice after dependencies update"
    echo -e "    -i  Ignore minor errors during build"
    echo -e "    -r  Reset source tree before build"
    echo -e "    -s# Sync options before build:"
    echo -e "        1 - Normal sync"
    echo -e "        2 - Make snapshot"
    echo -e "        3 - Restore previous snapshot, then snapshot sync"
    echo -e "    -o# Only build:"
    echo -e "        1 - Boot Image"
    echo -e "        2 - Recovery Image"
    echo -e "    -p  Build using pipe"
    echo -e "    -w  Log file options:"
    echo -e "        1 - Send warnings and errors to a log file"
    echo -e "        2 - Send all output to a log file"
    echo ""
    echo -e "${bldblu}  Example:${bldcya}"
    echo -e "    ./build-kek.sh -c1 shamu"
    echo -e "${rst}"
    exit 1
}


# Import Colors
. ./vendor/kek/tools/colors

# Kek version
export KEK_VERSION_MAJOR="Alpha"
export KEK_VERSION_MINOR="Testing"
export KEK_VERSION_MAINTENANCE="Unofficial"

# Default global variable values with preference to environmant.
if [ -z "${USE_CCACHE}" ]; then
    export USE_CCACHE=1
fi

# Maintenance logic
export KEK_VERSION="$KEK_VERSION_MAJOR $KEK_VERSION_MINOR $KEK_VERSION_MAINTENANCE"

# Check directories
if [ ! -d ".repo" ]; then
    echo -e "${bldred}No .repo directory found. Is this an Android build tree?${rst}"
    echo ""
    exit 1
fi
if [ ! -d "vendor/kek" ]; then
    echo -e "${bldred}No vendor/kek directory found. Is this a Kek build tree?${rst}"
    echo ""
    exit 1
fi

# Figure out the output directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisDIR="${PWD##*/}"

if [ -n "${OUT_DIR_COMMON_BASE+x}" ]; then
    RES=1
else
    RES=0
fi

if [ $RES = 1 ];then
    export OUTDIR=$OUT_DIR_COMMON_BASE/$thisDIR
    echo -e "${bldcya}External out directory is set to: ${bldgrn}($OUTDIR)${rst}"
    echo ""
elif [ $RES = 0 ];then
    export OUTDIR=$DIR/out
    echo -e "${bldcya}No external out, using default: ${bldgrn}($OUTDIR)${rst}"
    echo ""
else
    echo -e "${bldred}NULL"
    echo -e "Error, wrong results!${rst}"
    echo ""
fi


# Get OS (Linux / Mac OS X)
IS_DARWIN=$(uname -a | grep Darwin)
if [ -n "$IS_DARWIN" ]; then
    CPUS=$(sysctl hw.ncpu | awk '{print $2}')
else
    CPUS=$(grep "^processor" /proc/cpuinfo -c)
fi


opt_clean=0
opt_ccache=0
opt_extra=0
opt_jobs="$CPUS"
opt_kr=0
opt_ignore=0
opt_only=0
opt_pipe=0
opt_reset=0
opt_sync=0
opt_log=0


while getopts "ab:c:de:fj:kilo:prs:w:" opt; do
    case "$opt" in
    c) opt_clean="$OPTARG" ;;
    d) opt_ccache=1 ;;
    e) opt_extra="$OPTARG" ;;
    j) opt_jobs="$OPTARG" ;;
    k) opt_kr=1 ;;
    i) opt_ignore=1 ;;
    o) opt_only="$OPTARG" ;;
    p) opt_pipe=1 ;;
    r) opt_reset=1 ;;
    s) opt_sync="$OPTARG" ;;
    w) opt_log="$OPTARG" ;;
    *) usage
    esac
done

shift $((OPTIND-1))
if [ "$#" -ne 1 ]; then
    usage
fi
device="$1"


# Ccache options
if [ "$opt_ccache" -eq 1 ]; then
    echo -e "${bldcya}Ccache not be used in this build${rst}"
    unset USE_CCACHE
    echo ""
fi

# Kek device dependencies
echo -e "${bldcya}Looking for Kek product dependencies${bldgrn}"
if [ "$opt_kr" -ne 0 ]; then
    vendor/kek/tools/getdependencies.py "$device" "$opt_kr"
else
    vendor/kek/tools/getdependencies.py "$device"
fi
echo -e "${rst}"


# Check if last build was made ignoring errors
# Set if unset
if [ -f ".ignore_err" ]; then
   : ${TARGET_IGNORE_ERRORS:=$(cat .ignore_err)}
else
   : ${TARGET_IGNORE_ERRORS:=false}
fi

export TARGET_IGNORE_ERRORS

if [ "$TARGET_IGNORE_ERRORS" == "true" ]; then
   opt_clean=1
   echo -e "${bldred}Last build ignored errors. Cleaning Out${rst}"
   unset TARGET_IGNORE_ERRORS
   echo -e "false" > .ignore_err
fi


# Cleaning out directory
if [ "$opt_clean" -eq 1 ]; then
    echo -e "${bldcya}Cleaning output directory${rst}"
    make clean >/dev/null
    echo -e "${bldcya}Output directory is: ${bldgrn}Clean${rst}"
    echo ""
elif [ "$opt_clean" -eq 2 ]; then
    . build/envsetup.sh
    lunch "kek_$device-userdebug"
    make installclean >/dev/null
    echo -e "${bldcya}Output directory is: ${bldred}Dirty${rst}"
    echo ""
else
    if [ -d "$OUTDIR/target" ]; then
        echo -e "${bldcya}Output directory is: ${bldylw}Untouched${rst}"
        echo ""
    else
        echo -e "${bldcya}Output directory is: ${bldgrn}Clean${rst}"
        echo ""
    fi
fi

# Reset source tree
if [ "$opt_reset" -ne 0 ]; then
    echo -e "${bldcya}Resetting source tree and removing all uncommitted changes${rst}"
    repo forall -c "git reset --hard HEAD; git clean -qf"
    echo ""
fi

# Repo sync/snapshot
if [ "$opt_sync" -eq 1 ]; then
    # Sync with latest sources
    echo -e "${bldcya}Fetching latest sources${rst}"
    repo sync -j"$opt_jobs"
    echo ""
elif [ "$opt_sync" -eq 2 ]; then
    # Take snapshot of current sources
    echo -e "${bldcya}Making a snapshot of the repo${rst}"
    repo manifest -o snapshot-"$device".xml -r
    echo ""
elif [ "$opt_sync" -eq 3 ]; then
    # Restore snapshot tree, then sync with latest sources
    echo -e "${bldcya}Restoring last snapshot of sources${rst}"
    echo ""
    cp snapshot-"$device".xml .repo/manifests/

    # Prevent duplicate projects
    cd .repo/local_manifests
    for file in *.xml; do
        mv "$file" "$(echo $file | sed 's/\(.*\.\)xml/\1xmlback/')"
    done

    # Start snapshot file
    cd "$DIR"
    repo init -m snapshot-"$device".xml
    echo -e "${bldcya}Fetching snapshot sources${rst}"
    echo ""
    repo sync -d -j"$opt_jobs"

    # Prevent duplicate backups
    cd .repo/local_manifests
    for file in *.xmlback; do
        mv "$file" "$(echo $file | sed 's/\(.*\.\)xmlback/\1xml/')"
    done

    # Remove snapshot file
    cd "$DIR"
    rm -f .repo/manifests/snapshot-"$device".xml
    repo init
fi

# Setup environment
echo -e "${bldcya}Setting up environment${rst}"
echo -e "${bldmag}${line}${rst}"
. build/envsetup.sh
echo -e "${bldmag}${line}${rst}"

# This will create a new build.prop with updated build time and date
rm -f "$OUTDIR"/target/product/"$device"/system/build.prop

# This will create a new .version for kernel version is maintained on one
rm -f "$OUTDIR"/target/product/"$device"/obj/KERNEL_OBJ/.version

# Lunch device
echo ""
echo -e "${bldcya}Lunching device${rst}"
lunch "kek_$device-userdebug"

# Pipe option
if [ "$opt_pipe" -ne 0 ]; then
    export TARGET_USE_PIPE=true
else
    unset TARGET_USE_PIPE
fi

# Get extra options for build
if [ "$opt_extra" -eq 1 ]; then
    opt_v=" "showcommands
elif [ "$opt_extra" -eq 2 ]; then
    opt_v=" "-s
else
    opt_v=""
fi

# Ignore minor errors during build
if [ "$opt_ignore" -eq 1 ]; then
    opt_i=" "-k
    export TARGET_IGNORE_ERRORS=true
    echo -e "true" > .ignore_err
    if [ "$opt_log" -eq 0 ]; then
        opt_log=1
    fi
else
    opt_i=""
fi

# Log file options
if [ "$opt_log" -ne 0 ]; then
    rm -rf build.log
    if [ "$opt_log" -eq 1 ]; then
        exec 2> >(sed -r 's/'$(echo -e "\033")'\[[0-9]{1,2}(;([0-9]{1,2})?)?[mK]//g' | tee -a build.log)
    else
        exec &> >(tee -a build.log)
    fi
fi

# Start compilation
if [ "$opt_only" -eq 1 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Boot Image only${rst}"
    echo ""
    make -j$opt_jobs$opt_v$opt_i bootimage
elif [ "$opt_only" -eq 2 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Recovery Image only${rst}"
    echo ""
    make -j$opt_jobs$opt_v$opt_i recoveryimage
else
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building ${bldylw}KEK-ROM ${bldmag}$KEK_VERSION_MAJOR ${bldcya}$KEK_VERSION_MINOR ${bldred}$$KEK_VERSION_MAINTENANCE${rst}"
    echo ""
    make -j$opt_jobs$opt_v$opt_i bacon
fi


# Cleanup unused built
rm -f "$OUTDIR"/target/product/"$device"/cm-*.*
rm -f "$OUTDIR"/target/product/"$device"/kek_*-ota*.zip
