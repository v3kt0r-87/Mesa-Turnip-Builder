**Nov 20, 2026**: Updated Mesa to v26.3.1

## KernelSU, Magisk, and APatch supported
## Android 14 and above required to install

* ✅ **Turnip (Vulkan driver)** upgraded to **Mesa 26.3.1**, synced with latest upstream changes.
* ⚡ Continued **performance improvements** and **bug fixes** for various Vulkan games and applications.
* 🎮 Enhanced compatibility and support for newer **Qualcomm Adreno GPUs**.
* 🧩 Additional tuning for Android-specific driver quirks and rendering edge cases.

### 🛠️ Build Info
* 🧼 All binaries **stripped using `llvm-strip`** to reduce size and remove debug info.
* ⚙️ Compiled using **Android NDK r30**.

### 🤝 Credits
* **Build & Maintenance:** [**v3kt0r-87 (Shankar Vallabhan)**](https://github.com/v3kt0r-87)
* **Telegram:** [@VEKTOR_87](https://t.me/VEKTOR_87)
* **Community Group:** [adreno_driver](https://t.me/adreno_driver_support_group)

---

**Sep 19, 2026**: Updated Mesa to v26.2.3

**Magisk, KernelSU, and APatch supported**

**Requires Android 14 to install**

1. Updated Mesa to v26.2.3
2. Updated Android NDK to stable r30
3. Fixed SELinux context for vulkan driver (`same_process_hal_file`)
4. Optimized GPU Cache Cleaner to single-pass targeted traversal (fixes installer freezes)
5. Added cache cleanup on module uninstallation
6. Added DT_SONAME patching and symbol stripping (`llvm-strip`)
7. Fixed module installer compatibility and syntax checks

---

**Aug 14, 2026**: Updated Mesa to v26.2.0

Turnip drivers from now on will be delayed as I no longer have time / interest to maintain this.

I will try to keep this project up to date as much as I can.

**Magisk and KernelSU supported**

**Requires Android 14 to install**

1. Updated Android NDK to 30 beta2
2. LTO support removed to fix issues when building Mesa 26.2.0
3. Added uninstall script and minor improvements
4. Updated minimum Magisk version to v25.0
5. Now supports auto-updates via Magisk / KernelSU
6. GPU Cache Cleaner is now included in MAGISK / KSU builds (no manual cleanup needed)
