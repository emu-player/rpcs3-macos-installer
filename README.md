# RPCS3 Automatic Installer for macOS

<div align="center">

**Automated installation script for RPCS3 PS3 Emulator on macOS**

[![macOS](https://img.shields.io/badge/macOS-11.0+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![RPCS3](https://img.shields.io/badge/RPCS3-Latest-red.svg)](https://rpcs3.net)

</div>

## 🎮 What is RPCS3?

RPCS3 is a free and open-source PlayStation 3 emulator for Windows, Linux, and macOS. This script automates the installation process on macOS systems.

**Official RPCS3 Website:** https://rpcs3.net

## ✨ Features

- ✅ **Fully Automated** - One command installation
- 🔍 **System Validation** - Checks macOS version, architecture, disk space
- 📥 **Automatic Downloads** - RPCS3 and PS3 firmware
- ⚙️ **Optimized Config** - Pre-configured settings for best performance
- 🍎 **Apple Silicon Support** - M1/M2/M3/M4 optimizations
- 📝 **Detailed Logging** - Full installation log for troubleshooting
- 🧹 **Automatic Cleanup** - Removes temporary files after installation

## 📋 Requirements

### Minimum Requirements
- **OS:** macOS 11.0 (Big Sur) or newer
- **CPU:** Intel Core i5 or Apple Silicon (M1/M2/M3/M4)
- **RAM:** 8 GB
- **GPU:** OpenGL 4.3 or Vulkan compatible
- **Storage:** 5 GB free space

### Recommended Requirements
- **OS:** macOS 13.0 (Ventura) or newer
- **CPU:** Intel Core i7 or Apple Silicon M2/M3/M4
- **RAM:** 16 GB
- **GPU:** Dedicated GPU with Vulkan support
- **Storage:** 10+ GB free space

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/emu-player/rpcs3-macos-installer/main/rpcs3-installer.sh | bash
```

### Manual Installation

1. **Download the script:**
   ```bash
   curl -O https://raw.githubusercontent.com/emu-player/rpcs3-macos-installer/main/rpcs3-installer.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x rpcs3-installer.sh
   ```

3. **Run the installer:**
   ```bash
   ./rpcs3-installer.sh
   ```

4. **Follow the on-screen instructions**

## 📖 What Does This Script Do?

1. **Pre-Installation Checks:**
   - Verifies macOS version compatibility
   - Detects CPU architecture (Intel/Apple Silicon)
   - Checks available disk space
   - Tests internet connectivity

2. **Downloads:**
   - Latest RPCS3 build from official GitHub
   - Official PS3 firmware from Sony servers

3. **Installation:**
   - Installs RPCS3 to `/Applications`
   - Installs PS3 firmware
   - Creates optimized configuration
   - Sets up data directories
   - Creates desktop shortcut

4. **Post-Installation:**
   - Removes quarantine attributes
   - Cleans up temporary files
   - Generates installation log

## 🔧 Manual Setup (If Script Fails)

If the automatic installation doesn't work, you can install manually:

### Method 1: Download from Website
1. Visit https://rpcs3.net/download
2. Download the macOS version
3. Open the DMG file
4. Drag RPCS3.app to Applications
5. Launch RPCS3
6. Go to File → Install Firmware
7. Download firmware from: https://www.playstation.com/en-us/support/hardware/ps3/system-software/

### Method 2: Using Homebrew
```bash
brew install --cask rpcs3
```

## 🎯 Post-Installation Steps

### 1. Add Your Games

**Supported Formats:**
- Disc images (ISO, BIN/CUE)
- PSN packages (PKG)
- Game folders (GAMES folder structure)
- Digital games (RAP files for activation)

**How to add:**
1. Open RPCS3
2. Go to `File → Add Games`
3. Navigate to your game files
4. Select the folder containing your games

### 2. Configure Controller

**PlayStation Controller (Recommended):**
1. Connect your DualShock 3/4 or DualSense controller via USB or Bluetooth
2. Go to `Pads → Configure`
3. Select your controller
4. Map buttons as needed

**Xbox Controller:**
1. Connect via USB or Bluetooth
2. Go to `Pads → Configure`
3. Select "XInput" handler
4. Map buttons

**Keyboard:**
- Pre-configured with WASD + arrow keys

### 3. Optimize Settings

The script applies optimized settings, but you can customize:

**GPU Settings:**
- `GPU → Renderer` - Use Vulkan for best performance
- `GPU → Resolution Scale` - 100% for native, higher for upscaling
- `GPU → Anisotropic Filter` - 16x recommended

**CPU Settings:**
- `CPU → PPU Decoder` - LLVM Recompiler (fastest)
- `CPU → SPU Decoder` - LLVM Recompiler (fastest)

**Audio Settings:**
- `Audio → Renderer` - Cubeb (recommended)

### 4. Check Game Compatibility

Not all games run perfectly. Check compatibility at:
**https://rpcs3.net/compatibility**

**Compatibility Levels:**
- 🟢 **Playable** - Runs from start to finish with good performance
- 🟡 **Ingame** - Reaches gameplay but has issues
- 🟠 **Intro** - Starts but crashes before gameplay
- 🔴 **Loadable** - Shows loading screen only
- ⚫ **Nothing** - Doesn't boot

## ❓ Troubleshooting

### RPCS3 Won't Launch

**Error: "RPCS3 is damaged and can't be opened"**

Solution:
```bash
sudo xattr -rd com.apple.quarantine /Applications/RPCS3.app
```

**Error: "RPCS3 can't be opened because Apple cannot check it"**

Solution:
1. Right-click on RPCS3
2. Select "Open"
3. Click "Open" in the security dialog
4. Enter your password if prompted

### No Vulkan Support

**Symptom:** RPCS3 only shows OpenGL renderer

Solution:
1. Update macOS to the latest version
2. Update GPU drivers
3. For Intel Macs: Some models don't support Vulkan
4. Use OpenGL renderer instead (slower but works)

### Poor Performance

**Solutions:**
1. Lower resolution scale to 100%
2. Disable anti-aliasing
3. Use Vulkan renderer (if available)
4. Close other applications
5. Check game compatibility (some games run better than others)
6. For Apple Silicon: Ensure "Rosetta 2" is installed

### Firmware Installation Failed

**Manual Installation:**
1. Download firmware from: https://www.playstation.com/en-us/support/hardware/ps3/system-software/
2. Look for file named `PS3UPDAT.PUP`
3. In RPCS3: `File → Install Firmware`
4. Select the downloaded PUP file

### Games Not Showing Up

**Solutions:**
1. Check file format (must be ISO, PKG, or game folder)
2. Refresh game list: `File → Refresh Game List`
3. Add games folder: `File → Add Games`
4. Check folder permissions

### Controller Not Working

**Solutions:**
1. Update controller drivers
2. Try USB connection instead of Bluetooth
3. Reconfigure in `Pads → Configure`
4. For DualShock 3: May need SCP Toolkit (Windows) or specific drivers
5. For DualSense: Update macOS to 11.3+

### Audio Crackling/Stuttering

**Solutions:**
1. Change audio backend in settings
2. Increase audio buffer size
3. Enable "Time Stretching"
4. Close other audio applications

## 📊 Performance Tips

### Apple Silicon (M1/M2/M3/M4)

**Optimizations:**
- RPCS3 runs through Rosetta 2 translation
- Performance is excellent on M2 and newer
- M1 can struggle with demanding games
- Ensure sufficient cooling (MacBook Pro > MacBook Air)

**Settings for Apple Silicon:**
```
CPU:
  PPU: LLVM Recompiler
  SPU: LLVM Recompiler
  Max SPURS Threads: 8

GPU:
  Renderer: Vulkan (if available) or OpenGL
  Resolution Scale: 100-150%
  Relaxed ZCULL Sync: Enabled
```

### Intel Macs

**Optimizations:**
- Use Vulkan if GPU supports it
- Lower resolution for integrated graphics
- Better performance on discrete GPUs

**Settings for Intel:**
```
CPU:
  PPU: LLVM Recompiler
  SPU: LLVM Recompiler
  Max SPURS Threads: 6

GPU:
  Renderer: Vulkan
  Resolution Scale: 100%
```

## 🗂️ File Locations

```
/Applications/RPCS3.app                          # RPCS3 application
~/Library/Application Support/rpcs3/             # Data directory
~/Library/Application Support/rpcs3/config.yml   # Configuration file
~/Library/Application Support/rpcs3/games/       # Game saves and data
~/Library/Application Support/rpcs3/dev_hdd0/    # Virtual PS3 hard drive
~/rpcs3_install.log                              # Installation log
```

## 🔄 Updating RPCS3

To update RPCS3 to the latest version:

1. **Automatic (recommended):**
   - Run the installer script again
   - It will backup your config and update RPCS3

2. **Manual:**
   - Download latest build from https://rpcs3.net/download
   - Replace the app in Applications folder
   - Your games and settings will be preserved

## 🗑️ Uninstallation

To completely remove RPCS3:

```bash
# Download and run the uninstaller
curl -fsSL https://raw.githubusercontent.com/emu-player/rpcs3-macos-installer/main/uninstall.sh | bash
```

Or manually:
```bash
rm -rf /Applications/RPCS3.app
rm -rf ~/Library/Application\ Support/rpcs3
rm -rf ~/Library/Preferences/rpcs3
rm -rf ~/Library/Caches/rpcs3
```

## ⚖️ Legal Information

### Important Disclaimers

1. **PS3 Firmware:** The PS3 firmware is copyrighted by Sony Interactive Entertainment. This script downloads it from Sony's official servers. You must own a PS3 console to legally use this firmware.

2. **Game ROMs:** You must own a physical copy of any game you emulate. Downloading games you don't own is illegal in most countries.

3. **RPCS3 License:** RPCS3 is open-source software licensed under GPL v2.

4. **This Script:** This installation script is provided "as is" without warranty. Use at your own risk.

### Legal Ways to Obtain Games

- ✅ Rip games from your own PS3 discs
- ✅ Download digital purchases from your PSN account
- ✅ Purchase games from legal sources
- ❌ Download from torrent sites
- ❌ Use games you don't own

## 🤝 Contributing

This script is open-source! Contributions welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 🐛 Reporting Issues

Found a bug? Please report it:

1. Check existing issues
2. Create a new issue with:
   - macOS version
   - CPU architecture
   - Installation log (`~/rpcs3_install.log`)
   - Error messages
   - Steps to reproduce

## 📞 Support

- **RPCS3 Official Discord:** https://discord.me/RPCS3
- **RPCS3 Wiki:** https://wiki.rpcs3.net
- **GitHub Issues:** [Report a problem](https://github.com/emu-player/rpcs3-macos-installer/issues)

## 📜 License

This installation script is licensed under the MIT License.

RPCS3 is licensed under the GNU General Public License v2.0.

## 🙏 Credits

- **RPCS3 Team** - For creating this amazing emulator
- **Sony** - For the PS3 firmware
- **Community** - For testing and feedback

## ⚠️ Disclaimer

This is an unofficial installation script. It is not affiliated with or endorsed by the RPCS3 team or Sony Interactive Entertainment.

---

<div align="center">

**Made with ❤️ for the emulation community**

[RPCS3 Website](https://rpcs3.net) • [Compatibility List](https://rpcs3.net/compatibility) • [Quick Start Guide](https://rpcs3.net/quickstart)

</div>
