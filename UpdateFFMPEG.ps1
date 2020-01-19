function msg($msg)
{
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 3
  $Host.UI.Write( "                                                                                                     ")
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 3
  Write-Host -Fore Magenta "Updating FFMPEG"
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 4
  $Host.UI.Write( "                                                                                                     ")
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 4
  Write-Host -Fore Red $msg
}
function update-FFMPEG {
  # Change this to -Format MM-yyy for once a month,
  # or HH-dd-MM-yyyy for once an hour
  $theDate = (Get-Date -Format dd-MM-yyyy)
  # This will be the ffmpeg executable directory:
  $ffmpegDir = 'C:\Program Files\ffmpeg\'
  mkdir $ffmpegDir -ErrorAction SilentlyContinue;
  #I like to put all my command line shit in here
  $commandLineDir = 'C:\usr\local\bin\'
  mkdir $commandLineDir -ErrorAction SilentlyContinue;
  # Zeranoe's latest build:
  $proxy = 'http://proxymv:3128'
  $URL = "https://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.zip"
  echo "Updating FFMPEG"
  # Check to see if it has been updated today
  if (test-Path ($ffmpegDir + "last_update-" + $theDate)){
    Write-Host "already updated ffmpeg today" -f "Green"
  } else {
    rm ($ffmpegDir + "last_update-*") -ErrorAction SilentlyContinue
    New-Item ($ffmpegDir + "last_update-" + $theDate) -type file 2>&1 1>$null
    echo( "Checking online for new FFMPEG version")
    $downloadPath = ($ffmpegDir + 'latest.zip')
    # Check to see if ImageMagick has been installed
    $IMVersion = (ls 'C:\Program Files\ImageMagick*\ffmpeg.exe')
    # Delete any old downloads
    echo( "deleting old downloads")
    rm $downloadPath -ErrorAction SilentlyContinue
    # Look in the ffmpeg directory for latest current versions
    $f=(ls $ffmpegDir -filter "ffmpeg-*"| ?{ $_.PSIsContainer }| sort lastWriteTime)
    if ($f.length -gt 0) {
      # There are current versions locally
      # Get the last write time of the latest version
      $D = (get-date $f[-1].LastWriteTime -format "yyyyMMdd HH:mm:ss")
      echo( "last version was $D")
      # Download a newer version if it exists (--time-cond)
      #curl.exe -x $proxy --time-cond $D $URL -o $downloadPath #2>&1 1>$null
      Invoke-WebRequest $URL -OutFile $downloadPath
    } else {
      # No current versions
      echo( "downloading for the first time")
      #curl.exe -x $proxy  $URL -o $downloadPath
      Invoke-WebRequest $URL -OutFile $downloadPath
    }
    if (test-Path $downloadPath){
      # There was a new version available
      echo( "New build of FFMPEG found, installing")
      # Unpack it to the ffmpeg program dir
      #(silently, remove "2>&1 1>$null" if you want to know what it's doing)
      &"7z.exe" x -y -o"$ffmpegDir" $downloadPath # 2>&1 1>$null
      # Delete the old links
      ls $ffmpegDir -file -filter "ff*.exe"|%{rm $_.fullname}
      if (test-path $commandLineDir -ErrorAction SilentlyContinue){
        ls $commandLineDir -file -filter "ff*.exe"|%{rm $_.fullname}
      }
      # Update the latest version
      $f=(ls $ffmpegDir -directory -filter "ffmpeg-*"|sort lastWriteTime)
      # Make new symlinks, er hardlinks, whateverr
      ls ($f[-1].fullname + "\bin")|%{
        New-Item -ItemType HardLink -Path ($ffmpegDir + $_.name) -Target $_.FullName
        if (test-path $commandLineDir -ErrorAction SilentlyContinue){
          New-Item -ItemType HardLink -Path ($commandLineDir + $_.name) -Target $_.FullName
        }
      }
      # Imagemagick brings its own version of ffmpeg,
      # Which ends up on the PATH, so replace it with a hardlink to this one
      #-------If you don't want this cut here ------
      if ($IMVersion.length -gt 0) {
        echo ( "Replacing the Image Magick version of FFMPEG")
        if (Test-Path ($IMVersion.fullname + ".dist")) {
          rm $IMVersion #Made a backup already
        } else {
          mv $IMVersion ($IMVersion.fullname + ".dist")
        }
        New-Item -ItemType HardLink -Path $IMVersion.fullname -Target ($ffmpegDir + "ffmpeg.exe")`
        -ErrorAction SilentlyContinue
      }
      #-------To here-------------------------
      rm $downloadPath 2>&1 1>$null
      #-------Update Path variable
            $p=(("C:\usr\local\bin;" + (ls Env:\Path).value).split(";"))
      Set-Content -path Env:\Path -value (($p|Get-Unique) -join ";")
    } else {
      echo( "Current build of FFMPEG is up to date.")
    }
  }
}
update-FFMPEG