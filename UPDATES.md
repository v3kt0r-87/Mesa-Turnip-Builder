# Update Changelog

**September 19, 2024** : Updated Mesa version to 24.2.3

1. Sorry for not uploading drivers on time , i had a leg injury 


**September 9, 2024** : Minor cleanup of turnip build script:

1. Please use either Ubuntu 22.04.4 or Debain 12.7 based distros to build driver

2. Android NDK was also updated from 27 to 27b (based on Clang 18)

3. Build script will now only use stable version of Mesa to build turnip driver (Currently using Mesa 24.2.2)


**🇮🇳 August 15, 2024** : Merged turnip build script (for emulators) with main build script:

1. This will make the build process much easier.

2. Both builds are working correctly

 
 **August 14, 2024** : The Freedreno Turnip Builder now includes an option for two types of builds:

1. **MAGISK / KERNELSU Module** - Standard build to be used with MAGISK or KERNEL-SU.

2. **Custom GPU Driver** - Build for emulators like Dolphin and PPSSPP, and other similar apps.
