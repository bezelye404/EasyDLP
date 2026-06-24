# easy-dlp WSL & Linux Guide

Just a quick guide to getting the linux/wsl port (`main.sh`) up and running.

## prerequisites

Make sure you have `yt-dlp` and `ffmpeg` (needed for audio conversion and merging formats) installed.

### setting up dependencies

Fire up your terminal and run these commands.

#### Debian/Ubuntu (WSL default):
```bash
# update your package list
sudo apt update

# install ffmpeg
sudo apt install -y ffmpeg

# grab yt-dlp directly (the apt package is usually pretty outdated)
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

---

## how to run

1. **open your terminal**
   Launch your wsl distro or linux terminal.

2. **cd into the project folder**
   If you're using wsl, your windows drives are mounted under `/mnt/`. Just cd into wherever you saved this:
   ```bash
   cd /mnt/c/Users/YOUR_USERNAME/path/to/the/repo
   ```

3. **make it executable**
   You only need to do this once before the first run:
   ```bash
   chmod +x main.sh
   ```

4. **fire it up**
   ```bash
   ./main.sh
   ```

---

## wsl compatibility notes

- the script automatically detects if it's running inside wsl.
- if it is, it finds your windows user profile and dumps your downloads straight into your windows **Downloads** folder. no need to dig around the linux file system to find your videos.
