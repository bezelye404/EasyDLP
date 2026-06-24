#!/bin/bash

# Detect if running in WSL to set download directory to Windows Downloads folder
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    WIN_USERPROFILE=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    if [ -n "$WIN_USERPROFILE" ]; then
        DOWNLOAD_DIR="$(wslpath "$WIN_USERPROFILE")/Downloads"
    else
        DOWNLOAD_DIR="$HOME/Downloads"
    fi
else
    DOWNLOAD_DIR="$HOME/Downloads"
fi

mkdir -p "$DOWNLOAD_DIR"

show_menu() {
    clear
    echo ""
    echo -ne "\e[33m"
    echo '      ______                     ____  __    ____ '
    echo '     / ____/___ ________  __    / __ \/ /   / __ \'
    echo '    / __/ / __ `/ ___/ / / /___/ / / / /   / /_/ /'
    echo '   / /___/ /_/ (__  ) /_/ /___/ /_/ / /___/ ____/ '
    echo '  /_____/\__,_/____/\__, /   /_____/_____/_/      '
    echo '                   /____/                         '
    echo -ne "\e[0m"
    echo ""
    echo "   ================================================================="
    echo "   ::::::::::::::          easy-dlp v1.1          ::::::::::::::"
    echo "   ================================================================="
    echo "   Works with YouTube, Twitter, Instagram, TikTok and more"
    echo ""
    echo "      [1] Best Quality Video            [6] Subtitle Only"
    echo "      [2] Audio Only (MP3)              [7] Custom Format"
    echo "      [3] Select Video Quality          [8] Update tool"
    echo "      [4] Download Playlist             [9] Quit"
    echo "      [5] Video with Subtitles"
    echo ""
    echo "   ================================================================="
    read -p "   Select an option (1-9): " secim

    case $secim in
        1) best_quality ;;
        2) audio_only ;;
        3) select_quality ;;
        4) download_playlist ;;
        5) video_with_subtitles ;;
        6) subtitle_only ;;
        7) custom_format ;;
        8) update_tool ;;
        9) exit 0 ;;
        *) 
            echo ""
            echo "   Invalid choice. Pick a number from 1 to 9."
            sleep 2
            show_menu 
            ;;
    esac
}

best_quality() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [1] Best Quality Video"
    echo "   -----------------------------------------------------------------"
    echo "   Grabs the highest quality video and audio and saves it as MP4."
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Downloading..."
    echo ""
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --merge-output-format mp4 -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Saved to $DOWNLOAD_DIR"
    else
        echo "   Something went wrong during the download."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

audio_only() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [2] Audio Only (MP3)"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Downloading and converting to MP3..."
    echo ""
    yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! MP3 saved to $DOWNLOAD_DIR"
    else
        echo "   Something went wrong during the download."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

select_quality() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [3] Select Video Quality"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Quality options:"
    echo "     [1] 2160p (4K UHD)"
    echo "     [2] 1440p (2K QHD)"
    echo "     [3] 1080p (Full HD)"
    echo "     [4] 720p  (HD)"
    echo "     [5] 480p  (SD)"
    echo "     [6] 360p"
    echo ""
    read -p "   Quality (1-6): " kalite

    case $kalite in
        1) res="2160" ;;
        2) res="1440" ;;
        3) res="1080" ;;
        4) res="720" ;;
        5) res="480" ;;
        6) res="360" ;;
        *)
            echo "Invalid quality."
            sleep 2
            show_menu
            return
            ;;
    esac

    echo ""
    echo "   Downloading in ${res}p..."
    echo ""
    yt-dlp -f "bestvideo[height<=$res][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=$res]+bestaudio/best[height<=$res]" --merge-output-format mp4 -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Saved to $DOWNLOAD_DIR"
    else
        echo "   Something went wrong during the download."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

download_playlist() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [4] Playlist"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Playlist URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Download options:"
    echo "     [1] Entire playlist"
    echo "     [2] Specific range"
    echo ""
    read -p "   Option (1-2): " plsecim

    mkdir -p "$DOWNLOAD_DIR/Playlist"

    if [ "$plsecim" == "2" ]; then
        echo ""
        read -p "   Start video number: " baslangic
        read -p "     End video number: " bitis
        echo ""
        echo "   Downloading from video $baslangic to $bitis..."
        echo ""
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --playlist-start "$baslangic" --playlist-end "$bitis" -o "$DOWNLOAD_DIR/Playlist/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" --yes-playlist "$url"
    else
        echo ""
        echo "   Downloading the playlist..."
        echo ""
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 -o "$DOWNLOAD_DIR/Playlist/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" --yes-playlist "$url"
    fi

    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Playlist saved to $DOWNLOAD_DIR/Playlist"
    else
        echo "   Finished, but there might have been errors with some videos."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

video_with_subtitles() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [5] Video with Subtitles"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Subtitle languages:"
    echo "     [1] Turkish (tr)"
    echo "     [2] English (en)"
    echo "     [3] All available"
    echo "     [4] Custom code (e.g., de, fr)"
    echo ""
    read -p "   Language (1-4): " altsecim

    case $altsecim in
        1) altdil="tr" ;;
        2) altdil="en" ;;
        3) altdil="all" ;;
        4) 
            echo ""
            read -p "   Language code: " altdil 
            ;;
        *)
            echo "Invalid option."
            sleep 2
            show_menu
            return
            ;;
    esac

    echo ""
    echo "   Downloading video and embedding '$altdil' subtitles..."
    echo ""
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-subs --write-auto-subs --sub-langs "$altdil" --embed-subs -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Saved to $DOWNLOAD_DIR"
    else
        echo "   Something went wrong. Subtitles might not be available."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

subtitle_only() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [6] Subtitle Only"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Subtitle languages:"
    echo "     [1] Turkish (tr)"
    echo "     [2] English (en)"
    echo "     [3] All available"
    echo ""
    read -p "   Language (1-3): " altsecim

    case $altsecim in
        1) altdil="tr" ;;
        2) altdil="en" ;;
        3) altdil="all" ;;
        *)
            echo "Invalid option."
            sleep 2
            show_menu
            return
            ;;
    esac

    echo ""
    echo "   Downloading subtitle files (.srt)..."
    echo ""
    yt-dlp --write-subs --write-auto-subs --sub-langs "$altdil" --skip-download --convert-subs srt -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Subtitles saved to $DOWNLOAD_DIR"
    else
        echo "   Couldn't find or download the subtitles."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

custom_format() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [7] Custom Format"
    echo "   -----------------------------------------------------------------"
    echo ""
    read -p "   Video URL: " url
    if [ -z "$url" ]; then
        echo ""
        echo "   You need to provide a URL."
        sleep 2
        show_menu
        return
    fi
    echo ""
    echo "   Fetching available formats..."
    echo ""
    yt-dlp -F "$url"
    echo ""
    echo "   Enter the format ID from the list above."
    echo "   (e.g., '137' for video only, '137+140' for video+audio)"
    echo ""
    read -p "   Format ID: " formatid
    echo ""
    echo "   Downloading format $formatid..."
    echo ""
    yt-dlp -f "$formatid" -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$url"
    echo ""
    if [ $? -eq 0 ]; then
        echo "   Done! Saved successfully."
    else
        echo "   Something went wrong. The ID might be invalid."
    fi
    echo ""
    read -p "Press enter to continue..." empty_var
    show_menu
}

update_tool() {
    clear
    echo ""
    echo "   -----------------------------------------------------------------"
    echo "   [8] Update Tool"
    echo "   -----------------------------------------------------------------"
    echo ""
    echo "   Checking for updates..."
    echo ""
    yt-dlp -U
    echo ""
    echo "   Update check finished."
    echo ""
    read -p "Press enter to go back..." empty_var
    show_menu
}

show_menu
