# Andronix-Termux-Proot-Chrome-Fix-XFCE-Ubuntu-22.04

A simple script aimed at modifying Ubuntu XFCE .desktop files so that Chrome can properly start and operate in a proot environment such as Andronix (tested on Ubuntu 22.04) on Android. This repairs startup issues associated with default apps settings.

## Problem

Chrome and Chromium browsers cannot run in proot environments (like Andronix on Android) without the `--no-sandbox` flag. When launched from desktop shortcuts or as default applications, they fail to start because the desktop files don't include this required flag.

## Solution

This script automatically finds and modifies Chrome/Chromium `.desktop` files to add the `--no-sandbox` flag to their launch commands, enabling proper functionality in proot environments.

## Features

- Automatically detects Chrome and Chromium desktop files
- Adds `--no-sandbox` flag to Exec lines
- Creates backups before modifying files
- Handles both system-wide (`/usr/share/applications`) and user-local (`~/.local/share/applications`) desktop files
- Updates desktop database after modifications
- Colorful output with clear status messages

## Requirements

- Ubuntu 22.04 (or similar) running in a proot environment (e.g., Andronix)
- XFCE desktop environment
- Chrome or Chromium browser installed
- Bash shell

## Installation

1. Download the script:
```bash
wget https://raw.githubusercontent.com/mr-tbot/Andronix-Termux-Proot-Chrome-Fix-XFCE-Ubuntu-22.04/main/chrome-proot-fix.sh
```

Or clone the repository:
```bash
git clone https://github.com/mr-tbot/Andronix-Termux-Proot-Chrome-Fix-XFCE-Ubuntu-22.04.git
cd Andronix-Termux-Proot-Chrome-Fix-XFCE-Ubuntu-22.04
```

2. Make the script executable:
```bash
chmod +x chrome-proot-fix.sh
```

## Usage

### For user-local desktop files:
```bash
./chrome-proot-fix.sh
```

### For system-wide desktop files (requires root):
```bash
sudo ./chrome-proot-fix.sh
```

The script will:
1. Search for Chrome/Chromium desktop files
2. Create backups of each file before modifying
3. Add `--no-sandbox` flag to Exec lines
4. Update the desktop database
5. Display a summary of changes

## What It Does

The script modifies lines in `.desktop` files from:
```
Exec=/usr/bin/google-chrome-stable %U
```

To:
```
Exec=/usr/bin/google-chrome-stable --no-sandbox %U
```

This allows Chrome/Chromium to:
- Start from desktop shortcuts
- Work as the default browser
- Open links from other applications
- Function properly in the proot environment

## Backup and Safety

- The script creates timestamped backups (e.g., `google-chrome.desktop.backup.20240115_143022`) before modifying any files
- If something goes wrong, you can restore from backups
- The script checks file permissions before attempting modifications

## Troubleshooting

### Permission Denied
If you get permission errors for system files, run with sudo:
```bash
sudo ./chrome-proot-fix.sh
```

### No Desktop Files Found
If the script reports no desktop files found:
- Verify Chrome/Chromium is installed: `which google-chrome chromium-browser`
- Check for desktop files manually: `ls /usr/share/applications/*chrome*.desktop`
- Desktop files may be in a non-standard location

### Chrome Still Won't Start
After running the script:
1. Restart your desktop session or reboot
2. Try launching Chrome from the terminal first: `google-chrome-stable --no-sandbox`
3. Check if there are other Chrome processes running: `pkill chrome`

## Tested On

- Ubuntu 22.04 XFCE in Andronix on Android
- Termux + proot environment

## Contributing

Contributions, issues, and feature requests are welcome!

## License

This project is open source and available under the MIT License.

## Disclaimer

This script modifies system files. While it creates backups, use at your own risk. Always ensure you have backups of important data.
