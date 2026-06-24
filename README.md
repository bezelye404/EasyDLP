# easy-dlp Guide

Just a quick guide to getting the scripts up and running on Windows, Linux, or WSL.

---

## Windows Guide

Running it on Windows is super simple.

### prerequisites

You need `yt-dlp` and `ffmpeg` installed and added to your system's PATH.

- Download `yt-dlp` from their [official installation guide](https://github.com/yt-dlp/yt-dlp#installation).
- Download `ffmpeg` from [here](https://ffmpeg.org/download.html) (needed for merging video/audio formats and converting to mp3).

Make sure both are added to your Windows Environment Variables (PATH) so they can be called from anywhere.

### how to run

1. Double-click `main.bat`.
2. Select your option in the menu. All downloads will go straight to your Windows **Downloads** folder.

---

## Linux & WSL Guide

### prerequisites

Make sure you have `yt-dlp` and `ffmpeg` installed.

#### setting up dependencies (Debian/Ubuntu/WSL default)
```bash
# update your package list
sudo apt update

# install ffmpeg
sudo apt install -y ffmpeg

# grab the latest yt-dlp binary (the apt package is usually pretty outdated)
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

### how to run

1. **open your terminal** (or WSL).
2. **cd into the project folder**:
   If you're using WSL, your Windows C drive is mounted under `/mnt/`. Just cd into wherever you saved this folder:
   ```bash
   cd /mnt/c/Users/YOUR_USERNAME/path/to/the/repo
   ```
3. **make the script executable** (only need to do this once):
   ```bash
   chmod +x main.sh
   ```
4. **fire it up**:
   ```bash
   ./main.sh
   ```

### wsl compatibility notes

- the script automatically detects if it's running inside WSL.
- if it is, it finds your Windows user profile and dumps your downloads straight into your Windows **Downloads** folder. no need to dig around the Linux file system to find your files.
