@echo off
chcp 65001 >nul 2>&1
title easy-dlp

:MENU
color 0e
cls
echo.
echo      ______                     ____  __    ____ 
echo     / ____/___ ________  __    / __ \/ /   / __ \
echo    / __/ / __ `/ ___/ / / /___/ / / / /   / /_/ /
echo   / /___/ /_/ (__  ) /_/ /___/ /_/ / /___/ ____/ 
echo  /_____/\__,_/____/\__, /   /_____/_____/_/      
echo                   /____/                         
echo.
echo   =================================================================
echo   ::::::::::::::          easy-dlp v1.1          ::::::::::::::
echo   =================================================================
echo   Works with YouTube, Twitter, Instagram, TikTok and more
echo.
echo      [1] Best Quality Video            [6] Subtitle Only
echo      [2] Audio Only (MP3)              [7] Custom Format
echo      [3] Select Video Quality          [8] Update tool
echo      [4] Download Playlist             [9] Quit
echo      [5] Video with Subtitles
echo.
echo   =================================================================
set /p "secim=   Select an option (1-9): "

if "%secim%"=="1" goto EN_IYI
if "%secim%"=="2" goto SADECE_SES
if "%secim%"=="3" goto KALITE_SEC
if "%secim%"=="4" goto PLAYLIST
if "%secim%"=="5" goto ALTYAZILI
if "%secim%"=="6" goto SADECE_ALTYAZI
if "%secim%"=="7" goto OZEL_FORMAT
if "%secim%"=="8" goto GUNCELLE
if "%secim%"=="9" goto CIKIS

echo.
echo   Invalid choice. Pick a number from 1 to 9.
timeout /t 2 >nul
goto MENU

:: =====================================================================
:EN_IYI
cls
echo.
echo   -----------------------------------------------------------------
echo   [1] Best Quality Video
echo   -----------------------------------------------------------------
echo   Grabs the highest quality video and audio and saves it as MP4.
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Downloading...
echo.
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --merge-output-format mp4 -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Saved to %USERPROFILE%\Downloads
) else (
    echo   Something went wrong during the download.
)
echo.
pause
goto MENU

:: =====================================================================
:SADECE_SES
cls
echo.
echo   -----------------------------------------------------------------
echo   [2] Audio Only (MP3)
echo   -----------------------------------------------------------------
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Downloading and converting to MP3...
echo.
yt-dlp -x --audio-format mp3 --audio-quality 0 -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! MP3 saved to %USERPROFILE%\Downloads
) else (
    echo   Something went wrong during the download.
)
echo.
pause
goto MENU

:: =====================================================================
:KALITE_SEC
cls
echo.
echo   -----------------------------------------------------------------
echo   [3] Select Video Quality
echo   -----------------------------------------------------------------
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Quality options:
echo     [1] 2160p (4K UHD)
echo     [2] 1440p (2K QHD)
echo     [3] 1080p (Full HD)
echo     [4] 720p  (HD)
echo     [5] 480p  (SD)
echo     [6] 360p
echo.
set /p "kalite=   Quality (1-6): "

if "%kalite%"=="1" set "res=2160"
if "%kalite%"=="2" set "res=1440"
if "%kalite%"=="3" set "res=1080"
if "%kalite%"=="4" set "res=720"
if "%kalite%"=="5" set "res=480"
if "%kalite%"=="6" set "res=360"

echo.
echo   Downloading in %res%p...
echo.
yt-dlp -f "bestvideo[height<=%res%][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=%res%]+bestaudio/best[height<=%res%]" --merge-output-format mp4 -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Saved to %USERPROFILE%\Downloads
) else (
    echo   Something went wrong during the download.
)
echo.
pause
goto MENU

:: =====================================================================
:PLAYLIST
cls
echo.
echo   -----------------------------------------------------------------
echo   [4] Playlist
echo   -----------------------------------------------------------------
echo.
set /p "url=   Playlist URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Download options:
echo     [1] Entire playlist
echo     [2] Specific range
echo.
set /p "plsecim=   Option (1-2): "

if "%plsecim%"=="2" goto PLAYLIST_ARALIK

echo.
echo   Downloading the playlist...
echo.
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 -o "%USERPROFILE%\Downloads\Playlist\%%(playlist_title)s\%%(playlist_index)s - %%(title)s.%%(ext)s" --yes-playlist "%url%"
goto PLAYLIST_BITIS

:PLAYLIST_ARALIK
echo.
set /p "baslangic=   Start video number: "
set /p "bitis=     End video number: "
echo.
echo   Downloading from video %baslangic% to %bitis%...
echo.
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --playlist-start %baslangic% --playlist-end %bitis% -o "%USERPROFILE%\Downloads\Playlist\%%(playlist_title)s\%%(playlist_index)s - %%(title)s.%%(ext)s" --yes-playlist "%url%"

:PLAYLIST_BITIS
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Playlist saved to %USERPROFILE%\Downloads\Playlist
) else (
    echo   Finished, but there might have been errors with some videos.
)
echo.
pause
goto MENU

:: =====================================================================
:ALTYAZILI
cls
echo.
echo   -----------------------------------------------------------------
echo   [5] Video with Subtitles
echo   -----------------------------------------------------------------
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Subtitle languages:
echo     [1] Turkish (tr)
echo     [2] English (en)
echo     [3] All available
echo     [4] Custom code (e.g., de, fr)
echo.
set /p "altsecim=   Language (1-4): "

if "%altsecim%"=="1" set "altdil=tr"
if "%altsecim%"=="2" set "altdil=en"
if "%altsecim%"=="3" set "altdil=all"
if "%altsecim%"=="4" (
    echo.
    set /p "altdil=   Language code: "
)

echo.
echo   Downloading video and embedding '%altdil%' subtitles...
echo.
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mp4 --write-subs --write-auto-subs --sub-langs "%altdil%" --embed-subs -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Saved to %USERPROFILE%\Downloads
) else (
    echo   Something went wrong. Subtitles might not be available.
)
echo.
pause
goto MENU

:: =====================================================================
:SADECE_ALTYAZI
cls
echo.
echo   -----------------------------------------------------------------
echo   [6] Subtitle Only
echo   -----------------------------------------------------------------
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Subtitle languages:
echo     [1] Turkish (tr)
echo     [2] English (en)
echo     [3] All available
echo.
set /p "altsecim=   Language (1-3): "

if "%altsecim%"=="1" set "altdil=tr"
if "%altsecim%"=="2" set "altdil=en"
if "%altsecim%"=="3" set "altdil=all"

echo.
echo   Downloading subtitle files (.srt)...
echo.
yt-dlp --write-subs --write-auto-subs --sub-langs "%altdil%" --skip-download --convert-subs srt -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Subtitles saved to %USERPROFILE%\Downloads
) else (
    echo   Couldn't find or download the subtitles.
)
echo.
pause
goto MENU

:: =====================================================================
:OZEL_FORMAT
cls
echo.
echo   -----------------------------------------------------------------
echo   [7] Custom Format
echo   -----------------------------------------------------------------
echo.
set /p "url=   Video URL: "
if "%url%"=="" (
    echo.
    echo   You need to provide a URL.
    timeout /t 2 >nul
    goto MENU
)
echo.
echo   Fetching available formats...
echo.
yt-dlp -F "%url%"
echo.
echo   Enter the format ID from the list above.
echo   (e.g., '137' for video only, '137+140' for video+audio)
echo.
set /p "formatid=   Format ID: "
echo.
echo   Downloading format %formatid%...
echo.
yt-dlp -f %formatid% -o "%USERPROFILE%\Downloads\%%(title)s.%%(ext)s" "%url%"
echo.
if %ERRORLEVEL%==0 (
    echo   Done! Saved successfully.
) else (
    echo   Something went wrong. The ID might be invalid.
)
echo.
pause
goto MENU

:: =====================================================================
:GUNCELLE
cls
echo.
echo   -----------------------------------------------------------------
echo   [8] Update Tool
echo   -----------------------------------------------------------------
echo.
echo   Checking for updates...
echo.
yt-dlp -U
echo.
echo   Update check finished. Press any key to go back.
echo.
pause
goto MENU

:: =====================================================================
:CIKIS
cls
echo.
echo   =================================================================
echo.
echo                     Thanks for using the tool!
echo.
echo   =================================================================
echo.
pause
exit
