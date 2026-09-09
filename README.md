# Freedreno Turnip Builder 

## Stable / RC Mesa + Android NDK <br> Use this build for stability ✅ 

Simple Bash script that aims to build a Turnip driver for **MAGISK / KERNELSU or EMULATORS**.

## What's New 🔥

**[Click Here](UPDATES.md)**
 
## How to Build Locally 🤔

Simply clone this repo and use **Bash** to build:

```bash
bash build-turnip.sh
```

Check the [Notes](#notes-) section below for more info.

## App Compatibility

| Name                                            | Status | Notes                                                                                        |
|-------------------------------------------------|--------|----------------------------------------------------------------------------------------------|
| 3DMark                                          | ✅     |                                                                                              |
| GRID™ Autosport                                 | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working (60 fps)                     |
| SpongeBob SquarePants Battle For Bikini Bottom  | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working (30 - 45 fps)                |
| CarX Street                                     | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working (30 - 45 fps)                |
| Dolphin Emulator                                | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working                              |
| PPSSPP                                          | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working                              |
| EggNS                                           | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working                              |
| ANGLE (com.android.angle)                       | ✅     |                                                                                              |
| GTA Trilogy - Definitive Edition                | ✅     | Tested by [@Ryder_7777](https://t.me/Ryder_7777)<br>Working (poor performance)               |
| Call of Duty: Warzone Mobile                    | ✅     | Tested by [@SeniorFurry](https://t.me/SeniorFurry)<br>Working (texture bugs, poor performance) |
| Hitman: Blood Money – Reprisal                  | ✅     | Tested by [@V3KT0R-87](https://github.com/V3KT0R-87)<br>Working (60 fps, medium graphics)     |

## Notes 📝

- **Important:** Android 15 (SDK 35) is needed for full Vulkan 1.4 support.
- Please use **Ubuntu 26.04** or any Linux distribution based on it.
- **Make sure you have a stable internet connection before proceeding** (use a VPN if your ISP throttles your speed).
- Make sure your Android version is `14` or above, otherwise you won't be able to install.
- Make sure you have the latest **Magisk / KernelSU** installed before proceeding.

## Credits 🙏

This project wouldn't be possible without the help of these amazing people:
 
- **[@MrMiy4mo](https://github.com/ilhan-athn7)** for creating the Turnip build script and letting me modify and learn from it.
- **[@Mesa3D Team](https://gitlab.freedesktop.org/mesa/mesa)** for giving us such amazing drivers so that we can further improve our device performance.
- **[Adreno Driver Support Group](https://t.me/adreno_driver)** for testing and sharing benchmarks.
