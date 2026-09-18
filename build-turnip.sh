#!/bin/bash -e

# Define colors for terminal output
green='\033[0;32m'
red='\033[0;31m'
nocolor='\033[0m'

# Define Android NDK version and download URL
ndkdir="android-ndk-r30"
ndkver="https://dl.google.com/android/repository/${ndkdir}-linux.zip"
sdkver="34"

# Define Mesa version and download URL
mesadir="mesa-mesa-26.2.3"
mesaver="https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-26.2.3/mesa-mesa-26.2.3.zip?ref_type=tags"

# Define working directories
workdir="$(pwd)/turnip_workdir"         # Base directory for all operations
magiskdir="$workdir/turnip_module"      # Directory to create the Magisk module

DRIVER_FILE="vulkan.turnip.so"          # Output Vulkan Driver (emulator)
META_FILE="meta.json"                   # Metadata

ZIP_FILE_MAGISK="Turnip-26.2.3-MAGISK-KSU.zip"
ZIP_FILE_EMULATOR="Turnip-26.2.3-EMULATOR.zip" 

# List of required packages to build the Turnip driver
deps="meson ninja patchelf unzip curl flex bison zip clang ccache pkg-config"
[ -t 1 ] && clear || true

echo "Checking system for required dependencies..."

# Check for required dependencies 
for deps_chk in $deps; do

    [ -t 1 ] && sleep 0.25 || true
    if command -v "$deps_chk" >/dev/null 2>&1; then
        if [ "$deps_chk" = "meson" ]; then
            meson_ver=$(meson --version 2>/dev/null || echo "0")
            if [ "$(printf '%s\n' "1.4.0" "$meson_ver" | sort -V | head -n1)" != "1.4.0" ]; then
                echo -e "$red - meson found ($meson_ver), but >= 1.4.0 is required. Upgrade with: pip3 install --upgrade --break-system-packages meson $nocolor"
                deps_missing=1
            else
                echo -e "$green - meson found ($meson_ver) $nocolor"
            fi
        else
            echo -e "$green - $deps_chk found $nocolor"
        fi
    else
        echo -e "$red - $deps_chk not found, cannot continue. $nocolor"
        deps_missing=1
    fi
done

if [ "${deps_missing:-0}" = "1" ]; then
    echo -e "$red Missing or outdated dependencies. Please install them and try again. $nocolor"
    exit 1
fi

[ -t 1 ] && sleep 1 || true
[ -t 1 ] && clear || true

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
curl -sSL --fail "$ndkver" --output "$ndkdir".zip

[ -t 1 ] && clear || true

echo "Extracting Android NDK..." $'\n'
unzip "$ndkdir".zip &> /dev/null
rm -f "$ndkdir".zip

# Download Mesa source
echo "Downloading Latest Mesa source ..." $'\n'
curl -sSL --fail "$mesaver" --output "$mesadir".zip

[ -t 1 ] && clear || true

echo "Extracting Mesa source..." $'\n'
unzip "$mesadir".zip &> /dev/null
rm -f "$mesadir".zip
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
fakecc_dir="$workdir/fake-cc"
mkdir -p "$fakecc_dir"

# Create symbolic links to NDK-Clang
ln -sf "$ndk_bin/clang" "$fakecc_dir/cc"
ln -sf "$ndk_bin/clang++" "$fakecc_dir/c++"

# Prepend both fake-cc and NDK bin to PATH
export PATH="$fakecc_dir:$ndk_bin:$PATH"

echo "Creating Meson cross file..." $'\n'

cat <<EOF >"android-aarch64.txt"
[binaries]
ar = '$ndk_bin/llvm-ar'
c = ['ccache', '$ndk_bin/aarch64-linux-android$sdkver-clang', '-Wno-deprecated-declarations', '-Wno-gnu-alignof-expression']
cpp = ['ccache', '$ndk_bin/aarch64-linux-android$sdkver-clang++', '--start-no-unused-arguments', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++', '--end-no-unused-arguments', '-Wno-error=c++11-narrowing', '-Wno-deprecated-declarations', '-Wno-gnu-alignof-expression']
c_ld = '$ndk_bin/ld.lld'
cpp_ld = '$ndk_bin/ld.lld'
strip = '$ndk_bin/llvm-strip'
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
if ! CC=clang CXX=clang++ meson setup build-android-aarch64 \
    --cross-file "$workdir/$mesadir/android-aarch64.txt" \
    --native-file "$workdir/$mesadir/native.txt" \
    -Dbuildtype=release \
    -Dplatforms=android \
    -Dplatform-sdk-version="$sdkver" \
    -Dandroid-stub=true \
    -Dgallium-drivers= \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds=kgsl \
    -Degl=disabled \
    -Dstrip=true &> "$workdir/meson_log"; then
    echo -e "$red Meson setup failed! Log: $nocolor"
    cat "$workdir/meson_log"
    exit 1
fi

# Compile build files using Ninja
echo "Compiling build files..." $'\n'
if ! ninja -C build-android-aarch64 &> "$workdir"/ninja_log; then
    echo -e "$red Ninja compilation failed! Log: $nocolor"
    cat "$workdir/ninja_log"
    exit 1
fi

echo "Stripping and patching driver binaries..." $'\n'
driver_src="$workdir/$mesadir/build-android-aarch64/src/freedreno/vulkan/libvulkan_freedreno.so"
if [ ! -f "$driver_src" ]; then
    echo -e "$red Build failed! libvulkan_freedreno.so not found at $driver_src $nocolor" && exit 1
fi

cp "$driver_src" "$workdir/libvulkan_freedreno.so"
cd "$workdir"

# Strip unneeded debug symbols to reduce size from ~60MB+ to ~15-20MB
"$ndk_bin/llvm-strip" --strip-unneeded libvulkan_freedreno.so

# Prepare driver files for Magisk and Emulator
cp libvulkan_freedreno.so vulkan.adreno.so
cp libvulkan_freedreno.so "$DRIVER_FILE"

# Set DT_SONAME using patchelf to match driver filenames
patchelf --set-soname vulkan.adreno.so vulkan.adreno.so
patchelf --set-soname "$DRIVER_FILE" "$DRIVER_FILE"

echo "Prepare magisk module structure..." $'\n'
p1="system/vendor/lib64/hw"
mkdir -p "$magiskdir/$p1"
cp "$workdir/vulkan.adreno.so" "$magiskdir/$p1/"
cd "$magiskdir"

meta="META-INF/com/google/android"
mkdir -p "$meta"

# Create update-binary
cat <<'EOF' >"$meta/update-binary"
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v25.2+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

if [ -f /data/adb/magisk/util_functions.sh ]; then
  . /data/adb/magisk/util_functions.sh
elif [ -f /data/adb/ksu/util_functions.sh ]; then
  . /data/adb/ksu/util_functions.sh
elif [ -f /data/adb/ap/util_functions.sh ]; then
  . /data/adb/ap/util_functions.sh
else
  require_new_magisk
fi

[ -n "$MAGISK_VER_CODE" ] && [ "$MAGISK_VER_CODE" -lt 25200 ] && require_new_magisk

install_module
exit 0
EOF

# Create updater-script
cat <<'EOF' >"$meta/updater-script"
#MAGISK
EOF

cat <<'EOF' >"uninstall.sh"
#!/system/bin/sh
find /data/user/*/*/*cache /data/data/*/*cache /data/user_de/*/*/*cache -mindepth 1 -maxdepth 3 \
    \( -iname "*shader*" -o -iname "*graphitecache*" -o -iname "*gpucache*" \) \
    -exec rm -rf {} + 2>/dev/null || true
EOF

cat <<EOF >"module.prop"
id=turnip-mesa
name=Freedreno Turnip Vulkan Driver STABLE
version=v26.2.3
versionCode=20260919
author=V3KT0R-87
description=Turnip is an open-source vulkan driver for devices with Adreno 6xx-8xx GPUs.
updateJson=https://raw.githubusercontent.com/v3kt0r-87/Mesa-Turnip-Builder/refs/heads/stable/update.json
EOF

cat <<'EOF' >"customize.sh"
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`

ui_print ""
ui_print "Version=$MODVER "
ui_print "MagiskVersion=$MAGISK_VER"
ui_print ""
ui_print "Freedreno Turnip Vulkan Driver -V3KT0R"
ui_print "Adreno Driver Support Group - Telegram"
ui_print ""
sleep 1.25

ui_print ""
ui_print "Checking Device info ..."
sleep 1.25

SDK_VER=$(getprop ro.build.version.sdk)
[ -z "$SDK_VER" ] && SDK_VER=$(getprop ro.system.build.version.sdk)
[ "${SDK_VER:-0}" -lt 34 ] && abort "Android 14 is now required! Aborting ..."
ui_print ""
ui_print "Everything looks fine .... proceeding"
ui_print ""
ui_print "Installing Driver Please Wait ..."
ui_print ""

sleep 1.25
set_perm_recursive $MODPATH/system 0 0 0755 0644
set_perm $MODPATH/system/vendor/lib64/hw/vulkan.adreno.so 0 0 0644 u:object_r:same_process_hal_file:s0

ui_print ""
ui_print " Cleaning GPU Cache ... Please wait!"
find /data/user/*/*/*cache /data/data/*/*cache /data/user_de/*/*/*cache -mindepth 1 -maxdepth 3 \
    \( -iname "*shader*" -o -iname "*graphitecache*" -o -iname "*gpucache*" \) \
    -exec rm -rf {} + 2>/dev/null || true

ui_print ""
ui_print "- GPU Cache Cleared ..."
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

chmod 0755 "$meta/update-binary"
chmod 0755 customize.sh
chmod 0755 uninstall.sh

zip -r "$workdir/$ZIP_FILE_MAGISK" * &> /dev/null

if [[ ! -f "$workdir/$ZIP_FILE_MAGISK" ]]; then
    echo -e "${red}Error: Zipping driver files failed.${nocolor}"
    exit 1
else
    [ -t 1 ] && clear || true

    echo " Its time to create Turnip build for EMULATOR"

    sleep 2

    cd "$workdir"

# Create meta.json file for turnip emulator
 cat <<EOF > "$META_FILE"
{
  "schemaVersion": 1,
  "name": "Freedreno Turnip Driver 26.2.3",
  "description": "Compiled using Android NDK 30",
  "author": "v3kt0r-87",
  "packageVersion": "3",
  "vendor": "Mesa3D",
  "driverVersion": "Vulkan 1.3/4",
  "minApi": 34,
  "libraryName": "vulkan.turnip.so"
}
EOF

# Zip the turnip .so file and meta.json file
    if ! zip "$workdir/$ZIP_FILE_EMULATOR" "$DRIVER_FILE" "$META_FILE" &> /dev/null; then
        echo -e "${red}Error: Zipping driver files failed.${nocolor}"
        exit 1
    fi

    [ -t 1 ] && clear || true

    echo -e "$green Build Finished :). $nocolor" $'\n'
    echo -e "$green-All done, you can take your drivers from here:$nocolor" $'\n'
    echo -e "Magisk-KSU Module : $workdir/$ZIP_FILE_MAGISK" $'\n' 
    echo -e "Emulator : $workdir/$ZIP_FILE_EMULATOR" $'\n'
    echo -e "Turnip Driver : $workdir/$DRIVER_FILE" $'\n'

    # Cleanup 
    rm -f "$META_FILE"

    # Clean up fake-cc directory and symbolic links on exit
    rm -rf "$fakecc_dir"

fi
