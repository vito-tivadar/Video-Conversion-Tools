# ------------------------------------- CONFIG: Resize Video ------------------------------------- #
$resizeVideo = $true
$resizeVideoSize = "1080"


# ---------------------------------- CONFIG: Output Video Format --------------------------------- #
# https://ffmpeg.org/ffmpeg-formats.html#Demuxers

if($false){
    # .mp4
    $outputFileExtension = "mp4"
    $encoder = "libx264"
}

if($true) {
    # .webm
    $outputFileExtension = "webm"
    $encoder = "libvpx-vp9"
}

# ------------------------------- CONFIG: Input & Output Directory ------------------------------- #
$inputDir = ".\input"
$outputDir = ".\output"

# ----------------------------------- CONFIG: Other Parameters ----------------------------------- #
$onlyUpdateVideosJsFile = $true
$jsOutputFileName = "videos";          # if this is changed, you need to update index.html file!






Clear-Host

$windowWidth = $Host.UI.RawUI.WindowSize.Width
$dashes = "-" * $windowWidth

Write-Host $dashes -ForegroundColor DarkRed
Write-Host "Starting Video Conversion" -ForegroundColor DarkRed
Write-Host $dashes -ForegroundColor DarkRed

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir
}

# Initialize an array to store file information
$fileInfoArray = @()

# Get all video files in the input directory
$videoFiles = Get-ChildItem -Path $inputDir -File

if($resizeVideo -eq $false) {
    $resizeVideoSize = ""
}

# Loop through each video file
foreach ($file in $videoFiles) {
    $inputFile = Join-Path -Path $inputDir -ChildPath ($file)
    $outputFile = Join-Path -Path $outputDir -ChildPath ($file.BaseName + "." + $outputFileExtension)

    # Prepare FFmpeg command
    $ffmpegCommand = @(
        "-i", $inputFile,
        "-c:v", $encoder,
        "-crf", "30",
        "-b:v", "0",
        "-an",
        "-loglevel", "error",
        "-stats"
    )

    # Add resize filter if ResizeVideo is true
    if ($resizeVideo) {
        $ffmpegCommand += "-vf", "scale=-1:$resizeVideoSize"
    }


    $ffmpegCommand += $outputFile
    

    # Write-Host $outputFile -ForegroundColor DarkGray

    # Convert the video using FFmpeg
    if($onlyUpdateVideosJsFile -eq $false) {
        & ffmpeg $ffmpegCommand
    }

    $resizeStatus = if ($resizeVideo) { "and resized to $resizeVideoSize" + "p" } else { "" }
    Write-Host "Converted $file $resizeStatus" -ForegroundColor DarkBlue


    # Get file sizes
    $inputSize = (Get-Item $inputFile).Length / 1MB
    $outputSize = (Get-Item $outputFile).Length / 1MB

    $inputExtension = (Get-Item $inputFile).Extension
    $outputExtension = (Get-Item $outputFile).Extension

    # Write-Host "$inputExtension $outputExtension" -ForegroundColor DarkGray

    $outputFileName = (Get-Item $outputFile).Name

    # Create file info object

        $resizeInfo = 

        if($resizeVideo) {
        }

    $fileInfo = [ordered]@{
        inputFile = [ordered]@{
            name = $file.Name
            path = $inputFile.Replace("\", "/")
            size = [math]::Round($inputSize, 3)
            sizeFormatted = "{0:N2} MB" -f ($inputSize)
            extension = $inputExtension.Substring(1,($inputExtension.Length-1))
        }
        outputFile = [ordered]@{
            name = $outputFileName
            path = $outputFile.Replace("\", "/")
            size = [math]::Round($outputSize, 3)
            sizeFormatted = "{0:N2} MB" -f ($outputSize)
            extension = $outputExtension.Substring(1,($outputExtension.Length-1))
        }
        resizeInfo = [ordered]@{
            resized = $resizeVideo
            newSize = $resizeVideoSize
        }

    }

    # Add file info to array
    $fileInfoArray += $fileInfo
}

# Convert the array to JSON
$jsonContent = $fileInfoArray | Sort-Object | ConvertTo-Json

# Create the JavaScript file content
$jsContent = "const $jsOutputFileName = $jsonContent;"

# Write the JavaScript file
$jsOutputFile = ".\$jsOutputFileName.js"
$jsContent | Out-File -FilePath $jsOutputFile -Encoding UTF8

Write-Host $dashes -ForegroundColor DarkRed

$finalMsg = "All videos have been converted to $outputFileExtension format"
if ($resizeVideo) {
    $finalMsg = $finalMsg + " and were resized to $videoSize" + "p."
}
else {
    $finalMsg = $finalMsg + "."
}
Write-Host $finalMsg -ForegroundColor DarkGreen

$jsOutputFile = $jsOutputFile.Replace("\", "/")
Write-Host "Video information has been saved to $jsOutputFile and can be used with Video Conversion Test Tool (./index.html)." -ForegroundColor DarkGreen

Write-Host $dashes -ForegroundColor DarkRed