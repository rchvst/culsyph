##############################################################################
# culture syphon tool | cs_syphon.ps1
##############################################################################

#  cs_syphon.ps1 (this file)
#    seeks out images in threads that don't already exist locally
#    starts those downloads as suspended bitstransfers
#
#  TO CUSTOMIZE WHAT BOARDS YOU ARE APPROPRIATING VISIT LINE 131
#    OTHERWISE IT WILL JUST DO /wg/
#
# legend for download scrolling:
#   D - File exists locally, won't download
#   Q - File exists in queue, but not locally
# ANY OTHER CHARACTER IS THE FIRST CHARACTER IN THE FILE EXTENSION
#   w wbem | p png | j jpg | g gif | e etc

# !!! YOU NEED TO DO THIS:
# SET THIS TO WHERE YOU WANT THE FILES TO GO AND SET THE DRIVE AS $BitsFilter
#   IN THE OTHER TWO FILES
."c:\temp\ydrive.ps1"
$StorageRoot = 'Y:\mecha\mpl_trimmed' # no trailing backslash


# should not need to change but hack away
$FCB = 'http://boards.4chan.org/b/catalog'
$DownloadList = @()
$4CURL = "http://i.4cdn.org/$Board/" #filename.ext

[version]$csyphon = [version]::new(1,0)
$banner = @"
     cs_syphon.ps1 | Queue Module $csyphon Activated
"@ 
$totalQueued = 1
Function ThreadDestroyer {
    param($ThreadURL,$JustID,$CurrentSite) 
    try {
        Switch ($CurrentSite) {
            '4c' {
                $ThreadToFileRegEx = 'a href="//([\S]+[\d]+\.[\w\d]{3,})"'
             }
            default { 'error site default';break }
        }
        ''
        write-host "[$(Get-date)] $JustID - $ThreadURL" -ForegroundColor white
        $ThreadSource = (Invoke-WebRequest -Uri $ThreadURL -ea 0 -TimeoutSec 10)    
        $ThreadSource = $ThreadSource.ToString()
        $Results = ([regex]::matches($ThreadSource,$ThreadToFileRegEx))
        $Results | % {
#            $deskr = $_
            $NowPic = $_.groups[1].value
            switch ($CurrentSite) {
                '4c' {
                    $SOurcePic = "http://$NowPic"
                    $FinalFile = (join-path $ThrNumba $(Split-Path -Path $NowPic -Leaf))
                }
            }
            $FinalFile = (join-path $Path $FinalFile)
            if (!(Test-Path $FinalFile -IsValid)) { write-host "Path Not Valid" -ForegroundColor red }
            new-item ([system.io.path]::GetDirectoryName($FinalFile)) -ItemType directory -Force | Out-Null
            if (!(test-path $FinalFile -PathType Leaf)) {
                write-host ([system.io.path]::GetExtension($FinalFile).Substring(1,1).ToUpper()) -NoNewline -ForegroundColor White -BackgroundColor DarkGreen
                if ((Get-BitsTransfer -Name "$FinalFile" -ea 0 | Measure-Object).Count -eq '0') {
                    if ($CurrentSite -eq '4C') {
                        if (($NowPic -like "i*") -and ($Nowpic -notlike "*.css")) {
                            #write-host $NowPic -ForegroundColor yellow
                            $totalQueued++
                            #"dest: $FinalFile"
                            #"src : $sourcepic"
                            #"description $_"
                            Start-BitsTransfer -Asynchronous -Destination $FinalFile -Source $SOurcePic  -Description "x $finalfile" -DisplayName "$FinalFile" -TransferPolicy Always -Priority foreground -RetryInterval 60 | Suspend-BitsTransfer | Out-Null
                            # IF YOU WANNA SLOW THINGS DOWN HERE'S A GOOD SPOT - ADDS A DELAY BETWEEN PROCESSING FILES IN THE THREAD.. 
                            #Start-Sleep -Milliseconds 100
                        } 
                    } 
                } else {
                    write-host "Q" -ForegroundColor Yellow # this is odd .. 
                }
            } else { write-host "D" -ForegroundColor Green -NoNewline } # save dem bits
        }
}
    catch [exception] {
        #write-host $($_.ToString()) -ForegroundColor darkMagenta -BackgroundColor white
        $_.FullyQualifiedErrorId
        $_ | Select *
        sleep -Seconds 5
        if ($_.FullyQualifiedErrorId -eq "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.ForEachObjectCommand") { #"DriveNotFound,Microsoft.PowerShell.Commands.JoinPathCommand") {
            "No access to save path - if it's a network drives, and you're running as admin, can process can see it? (admin vs. user) - this app works as regular user"
            Break
        }
    }
}

function BrandNewCat {
    param(
    $Site = '4C',
    $Board = 'r',
    $IsNotCat = 0,
    $Path="$($StorageRoot)\nogood/$board"
    )
    try {
        if (($site -eq '4C') -and ($Board)) {
            $URL = "http://boards.4chan.org/$board/catalog"
            $Path="$($StorageRoot)\4H/$board"
        } else { 
            "Should Not Happen"
            pause
            break
        }
    $CurrentSite = $Site
    Switch ($CurrentSite) {
        '4c' {
            $URL = "http://boards.4chan.org/$board/catalog"
            $CThreadRoot = "http://boards.4chan.org/$($Board)/thread/"
            $StoragePathLocal = "$($StorageRoot)\4H/$board"
            $CatToThreadRegEx = '"([\d]{4,})":'
         }
        default { break }
    }
        Write-Warning "[$(Get-date)] $URL"
        $BoardCatalogueSource = (Invoke-WebRequest -uri $URL -UserAgent $dpUserAgent -ea 0) 
        $BoardCatalogueSource = $BoardCatalogueSource.tostring()
        $Results = ([regex]::matches($BoardCatalogueSource,$CatToThreadRegEx)) 
        write-host "[$(Get-date)] Threads in Catalogue: $($Results.count)"
        $Results | % {
            $ThrNumba = $($_.groups[1].value)
            $cThreadURL  = "$($CThreadRoot)$($_.groups[1].value)"
            $cJustID = ($_.groups[1].value)
            #write-host $cThreadURL -ForegroundColor Cyan
            ThreadDestroyer -ThreadURL $cThreadURL -JustID $cJustID -CurrentSite $Site 
        }
    }
    catch [exception] {
        write-host ($_.ToString()) -ForegroundColor Magenta
        $_
        continue
    }
}
try {
    do {
        BrandNewCat -Site 4C -Board 'wg' # 4chan board name
        #
        # try your favourite board here
        #
        [console]::Beep(330,100)
        [console]::Beep(430,100)
        write-host "`r`nSleeping to be kind."
        sleep 10
    }
    while ($True)
}
catch {

}
finally {
    write-host "" -ForegroundColor Yellow
    $error
}
