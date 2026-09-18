# Freedreno Turnip Builder

### Stable Mesa + Android NDK (r30)

Simple Bash script to build Turnip Vulkan drivers for Magisk,KernelSU and Android Emulators.

## What's New

See the latest changes in [UPDATES.md](UPDATES.md) or grab prebuilts from [Releases](../../releases).

## How to Build Locally

Clone the repository and run the build script:

```bash
bash build-turnip.sh
```

Check the [Notes](#notes) section below for prerequisites.

## App Compatibility

| Name | Status | Notes |
|---|:---:|---|
| 3DMark | Working | |
| GRID™ Autosport | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>60 fps |
| SpongeBob SquarePants Battle For Bikini Bottom | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>30 - 45 fps |
| CarX Street | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>30 - 45 fps |
| Dolphin Emulator | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87) |
| PPSSPP | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87) |
| EggNS | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87) |
| ANGLE (com.android.angle) | Working | |
| GTA Trilogy - Definitive Edition | Working | Tested by [@Ryder_7777](https://t.me/Ryder_7777)<br>Poor performance |
| Call of Duty: Warzone Mobile | Working | Tested by [@SeniorFurry](https://t.me/SeniorFurry)<br>Texture bugs, poor performance |
| Hitman: Blood Money – Reprisal | Working | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>60 fps, medium graphics |

## Notes

- **Important:** Android 15 (SDK 35) is needed for full Vulkan 1.4 support.
- Requires Android 14+ (SDK 34+) to install the root module.
- Supports Magisk v25.2+, KernelSU, and APatch.
- Recommended build environment: Ubuntu 24.04 / 26.04 or any compatible Linux distribution.
- Ensure a stable internet connection for downloading the Android NDK and Mesa source.

## Credits

This project wouldn't be possible without the help of these people:

- [@MrMiy4mo](https://github.com/ilhan-athn7) for creating the Turnip build script and letting me modify and learn from it.
- [@Mesa3D Team](https://gitlab.freedesktop.org/mesa/mesa) for the graphics driver stack.
- [Adreno Driver Support Group](https://t.me/adreno_driver) for testing and sharing benchmarks.
