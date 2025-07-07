#!/bin/bash -e

# Define colors for terminal output
green='\033[0;32m'
red='\033[0;31m'
nocolor='\033[0m'

# Define Android NDK version and download URL
ndkdir="android-ndk-r29-beta2"
ndkver="https://dl.google.com/android/repository/${ndkdir}-linux.zip"
sdkver="34"

# Define Mesa version and download URL
mesadir="mesa-main"
mesaver="https://gitlab.freedesktop.org/mesa/mesa/-/archive/main/mesa-main.zip"

# Define working directories
workdir="$(pwd)/turnip_workdir"         # Base directory for all operations
magiskdir="$workdir/turnip_module"      # Directory to create the Magisk module

DRIVER_FILE="vulkan.turnip.so"          # Output Vulkan Driver (emulator)
META_FILE="meta.json"                   # Metadata

ZIP_FILE_MAGISK="Turnip-25.1.5-MAGISK-KSU-BETA.zip"
ZIP_FILE_EMULATOR="Turnip-25.1.5-EMULATOR-BETA.zip" 

# List of required packages to build the Turnip driver
deps="meson ninja patchelf unzip curl pip flex bison zip glslang"
clear

echo "Checking system for required dependencies..."

# Check for required dependencies 
for deps_chk in $deps; do

    sleep 0.5
    if command -v "$deps_chk" >/dev/null 2>&1; then
        echo -e "$green - $deps_chk found $nocolor"
    else
        echo -e "$red - $deps_chk not found, cannot continue. $nocolor"
        deps_missing=1

        if [ "$deps_missing" == "1" ]; then
            echo "Missing dependencies, installing them now..." $'\n'
            sudo apt install -y meson meson-1.5 patchelf unzip curl python3-pip flex bison zip python3-mako glslang-tools vulkan-tools python-is-python3 &> /dev/null
        fi
    fi
done

sleep 1.5
clear

# Clean work directory if it exists
if [ -d "$workdir" ]; then
    echo "Work directory already exists. Cleaning before proceeding..." $'\n'
    rm -rf "$workdir"
    sleep 2
fi

echo "Creating and entering the work directory..." $'\n'
mkdir -p "$workdir" && cd "$_"

# Download Android NDK
echo "Downloading Android NDK..." $'\n'
curl $ndkver --output "$ndkdir".zip &> /dev/null

clear

echo "Extracting Android NDK..." $'\n'
unzip "$ndkdir".zip &> /dev/null

# Download Mesa source
echo "Downloading Latest Mesa source ..." $'\n'
curl $mesaver --output "$mesadir".zip &> /dev/null

clear

echo "Extracting Mesa source..." $'\n'
unzip "$mesadir".zip &> /dev/null
cd $mesadir

# Set NDK Clang bin directory
ndk_bin="$workdir/$ndkdir/toolchains/llvm/prebuilt/linux-x86_64/bin"

# Set toolchain variables
export CC=clang
export CXX=clang++
export AR=llvm-ar
export RANLIB=llvm-ranlib
export STRIP=llvm-strip
export OBJDUMP=llvm-objdump
export OBJCOPY=llvm-objcopy
export LDFLAGS="-fuse-ld=lld"

# Create a temporary directory for fake cc/c++
mkdir -p /tmp/fake-cc

# Create symbolic links to NDK-Clang
ln -sf "$ndk_bin/clang" /tmp/fake-cc/cc
ln -sf "$ndk_bin/clang++" /tmp/fake-cc/c++

# Prepend both fake-cc and NDK bin to PATH
export PATH="/tmp/fake-cc:$ndk_bin:$PATH"

echo "Creating Meson cross file..." $'\n'

cat <<EOF >"android-aarch64.txt"
[binaries]
ar = '$ndk_bin/llvm-ar'
c = ['ccache', '$ndk_bin/aarch64-linux-android$sdkver-clang']
cpp = ['ccache', '$ndk_bin/aarch64-linux-android$sdkver-clang++', '--start-no-unused-arguments', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++', '--end-no-unused-arguments', '-Wno-error=c++11-narrowing']
c_ld = '$ndk_bin/ld.lld'
cpp_ld = '$ndk_bin/ld.lld'
strip = '$ndk_bin/aarch64-linux-android-strip'
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=NDKDIR/pkg-config', '/usr/bin/pkg-config']

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

cat <<EOF >"native.txt"
[build_machine]
c = ['ccache', 'clang']
cpp = ['ccache', 'clang++']
ar = 'llvm-ar'
strip = 'llvm-strip'
c_ld = 'ld.lld'
cpp_ld = 'ld.lld'
system = 'linux'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF

echo "Generating build files..." $'\n'
CC=clang CXX=clang++ meson setup build-android-aarch64 \
    --cross-file "$workdir/$mesadir/android-aarch64.txt" \
    --native-file "$workdir/$mesadir/native.txt" \
    -Dbuildtype=release \
    -Dplatforms=android \
    -Dplatform-sdk-version="$sdkver" \
    -Dandroid-stub=true \
    -Dgallium-drivers= \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds=kgsl \
    -Db_lto=true \
    -Db_lto_mode=thin \
    -Degl=disabled \
    -Dstrip=true &> $workdir/meson_log

# Compile build files using Ninja
echo "Compiling build files..." $'\n'
ninja -C build-android-aarch64 &> "$workdir"/ninja_log

echo "Using patchelf to match .so name..." $'\n'
cp "$workdir"/"$mesadir"/build-android-aarch64/src/freedreno/vulkan/libvulkan_freedreno.so "$workdir"
cd "$workdir"



if ! [ -a libvulkan_freedreno.so ]; then
    echo -e "$red Build failed! libvulkan_freedreno.so not found $nocolor" && exit 1
fi

echo "Prepare magisk module structure..." $'\n'
p1="system/vendor/lib64/hw"
mkdir -p "$magiskdir/$p1"
cd "$magiskdir"

echo "Copy necessary files from the work directory..." $'\n'
cp "$workdir"/libvulkan_freedreno.so "$workdir"/vulkan.adreno.so
cp "$workdir"/vulkan.adreno.so "$magiskdir/$p1"

meta="META-INF/com/google/android"
mkdir -p "$meta"

# Create update-binary
cat <<EOF >"$meta/update-binary"
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "\$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v25.2+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=\$2
ZIPFILE=\$3

mount /data 2>/dev/null

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ \$MAGISK_VER_CODE -lt 25200 ] && require_new_magisk

install_module
exit 0
EOF

# Create updater-script
cat <<EOF >"$meta/updater-script"
#MAGISK
EOF

cat <<EOF >"uninstall.sh"
find /data/user_de/*/*/*cache/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*graphitecache*" -exec rm -rf {} +
find /data/data/* -iname "*gpucache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*shader*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*graphitecache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*gpucache*" -exec rm -rf {} +
EOF

cat <<EOF >"module.prop"
id=turnip-mesa
name=Freedreno Turnip Vulkan Driver BETA
version=v25.2
versionCode=20250707
author=V3KT0R-87
description=Turnip is an open-source vulkan driver for devices with Adreno 6xx-7xx GPUs.
updateJson=https://raw.githubusercontent.com/v3kt0r-87/Mesa-Turnip-Builder/refs/heads/test/update.json
EOF

cat <<EOF >"customize.sh"
MODVER=\`grep_prop version \$MODPATH/module.prop\`
MODVERCODE=\`grep_prop versionCode \$MODPATH/module.prop\`

ui_print ""
ui_print "Version=\$MODVER "
ui_print "MagiskVersion=\$MAGISK_VER"
ui_print ""
ui_print "Freedreno Turnip Vulkan Driver BETA"
ui_print "Adreno Driver Support Group - Telegram"
ui_print ""
sleep 1.25

ui_print ""
ui_print "Checking Device info ..."
sleep 1.25

[ \$(getprop ro.system.build.version.sdk) -lt 34 ] && echo "Android 14 is now required! Aborting ..." && abort
echo ""
echo "Everything looks fine .... proceeding"
ui_print ""
ui_print "Installing Driver Please Wait ..."
ui_print ""

sleep 1.25
set_perm_recursive \$MODPATH/system 0 0 0755 0644
set_perm \$MODPATH/system/vendor/lib64/hw/vulkan.adreno.so 0 0 0644

ui_print ""
ui_print " Cleaning GPU Cache ... Please wait!"
ui_print " This might take a while ..."
ui_print ""

find /data/user_de/*/*/*cache/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*graphitecache*" -exec rm -rf {} +
find /data/data/* -iname "*gpucache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*shader*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*graphitecache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*gpucache*" -exec rm -rf {} +

ui_print ""
ui_print "- Gpu Cache Cleared ..."
ui_print ""

ui_print "Driver installed Successfully"
sleep 1.25

ui_print ""
ui_print "All done, Please REBOOT device"
ui_print ""
ui_print "BY: @VEKT0R_87"
ui_print ""
EOF

echo "Packing driver files into Magisk/KSU module ..." $'\n'

zip -r "$workdir/$ZIP_FILE_MAGISK" * &> /dev/null

if [[ ! -f "$workdir/$ZIP_FILE_MAGISK" ]]; then
    echo -e "${red}Error: Zipping driver files failed.${nocolor}"
    exit 1
else
    clear

    echo " Its time to create Turnip build for EMULATOR"

    sleep 2

    cd ..

    mv vulkan.adreno.so vulkan.turnip.so

# Create meta.json file for turnip emulator
 cat <<EOF > "$META_FILE"
{
  "schemaVersion": 1,
  "name": "Freedreno Turnip Driver BETA",
  "description": "Compiled using Android NDK 29",
  "author": "v3kt0r-87",
  "packageVersion": "3",
  "vendor": "Mesa3D",
  "driverVersion": "Vulkan 1.4",
  "minApi": 34,
  "libraryName": "vulkan.turnip.so"
}
EOF

# Zip the turnip .so file and meta.json file
    if ! zip "$workdir/$ZIP_FILE_EMULATOR" "$DRIVER_FILE" "$META_FILE" &> /dev/null; then
        echo -e "${red}Error: Zipping driver files failed.${nocolor}"
        exit 1
    fi

    clear

    echo -e "$green Build Finished :). $nocolor" $'\n'
    echo -e "$green-All done, you can take your drivers from here;$nocolor" $'\n'
    echo "$workdir/$ZIP_FILE_MAGISK"
    echo "$workdir/$ZIP_FILE_EMULATOR"

    # Cleanup 
    rm "$DRIVER_FILE" "$META_FILE"

    # Clean up fake-cc directory and symbolic links on exit
    rm -rf /tmp/fake-cc/cc
    rm -rf /tmp/fake-cc/c++
    rm -rf /tmp/fake-cc




fi