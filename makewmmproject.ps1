﻿param (
    [parameter(Mandatory=$true)]
    [string] $videoFile,
    [parameter(Mandatory=$true)]
    [string] $nameOfPresenter
)

Write-Host "Creating a NOUG Windows Movie Maker Template for a given Video" -foregroundcolor green

Write-Host "Video: $videoFile"
Write-Host "Presenter: $nameOfPresenter"


$scriptPath = Split-Path $myInvocation.InvocationName

$libs = Join-Path $scriptPath 'libs\Microsoft.WindowsAPICodePack.Shell.dll'

Add-Type -Path $libs

 
function Get-ShellProperty($shellFile, $propertName)
{
    $shellFile.Properties.DefaultPropertyCollection | foreach { if ($_.CanonicalName -eq $propertName) { return $_ }  }
}


function Get-DurationInSeconds($shellFile) {

  $property = Get-ShellProperty $shellFile 'System.Media.Duration'  
  [double] $property.Value * 0.0000001
}

function FormatDuration($duration)
{
    $formatted = "{0}" -f $duration
    $formatted.Replace(',','.') 
}


function Create-MovieMakerTemplate($fileName) {
    $shellFile = [Microsoft.WindowsAPICodePack.Shell.ShellFile]::FromFilePath($fileName)
    $templateName = Join-Path $scriptPath "noug-wmmv-template.wlmp"
    $fileName = $shellFile.Name
    
    $outFile = Split-path $shellFile.Path
    $outFile = Join-Path $outFile "$filename.wlmp"
    [XML]$template = get-content $templateName

    $duration  = Get-DurationInSeconds $shellFile

    $item = $template.Project.MediaItems.MediaItem | where-object { $_.id -eq '3' }
    $item.filePath = "$fileName.wmv"
    $item.duration = FormatDuration $duration


    $clip = $template.Project.Extents.AudioClip | where-object { $_.extentID -eq '35' }
    $clip.gapBefore = FormatDuration  ($duration -8.0000)

    $clip = $template.Project.Extents.TitleClip | where-object { $_.extentID -eq '31' }
    $clip.gapBefore = FormatDuration  ($duration - 3.0000)


    $clip = $template.Project.Extents.TitleClip | where-object { $_.extentID -eq '10' }
    $boundSet =  $clip.Effects.TextEffect.BoundProperties.BoundPropertyStringSet | where-object { $_.Name -eq 'string' }
    $boundSet.BoundPropertyStringElement.Value = 'präsentiert'    

    $clip = $template.Project.Extents.TitleClip | where-object { $_.extentID -eq '14' }
    $boundSet =  $clip.Effects.TextEffect.BoundProperties.BoundPropertyStringSet | where-object { $_.Name -eq 'string' }
    $boundSet.BoundPropertyStringElement[0].Value = ''    
    $boundSet.BoundPropertyStringElement[1].Value = $shellFile.Name    
    $boundSet.BoundPropertyStringElement[2].Value = ''    
    $boundSet.BoundPropertyStringElement[3].Value = "mit $nameOfPresenter"    
    
    $template.Save($outFile)
    Write-Host "Windows Movie Maker Project created $outfile" -foregroundcolor yellow
}

if (Test-Path $videoFile) {
    Create-MovieMakerTemplate($videoFile)

    $destPath = Split-Path $videoFile

    $mp3 = Join-Path $scriptPath "On The Edge Of Spring.mp3"

    Copy-Item $mp3 $destPath

    Write-Host "On The Edge of Sprint.mp3 copied to $destPath" -foregroundcolor yellow
} else { 
    Write-Host "The Video does not exists" -foregroundcolor red
}
