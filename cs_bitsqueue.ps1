##############################################################################
# cs_bitsqueue.ps1 | culture syphon module: bitstransfer queue jockey
##############################################################################
#
#    ensures up to a configurable queue count of bitstransfers are being
#    started from the pool of suspended bitstransfers (else network is kill)
#    to slow things down drop the queue size to a smaller number
#
##############################################################################

# YOU NEED TO SET AT LEAST THE BITSFILTER TO YOUR DOWNLOAD PATH IN CS_DiskWrite.ps1 & CS_BITSQueue.ps1
# set the following to the drive letter of your download folder with trailing backslash
$bitsfilter = 'Y:\' # *** Requires trailing backslash - is used to lazily filter for only my bits jobs
# for example my $StorageRoot is 'Y:\mecha\mpl_trimmed' in cs_syphon so I used 'y:\' for $bitsfilter
."c:\temp\ydrive.ps1"

# should not need to change but hack away
[int64]$RunningTotal = 0
[int]$BITS_DONE_COUNT = 0
$QueueSize = 40
[version]$csyphon = [version]::new(1,0)
$banner = @"
     cs_BitsTransfer.ps1 | Queue Module $csyphon Activated
"@ 
try {
    write-host $Banner -foregroundcolor green
    do {
        $BITS_ONGOING = (Get-BitsTransfer | where DisplayName -like "$bitsfilter*")| where jobstate -eq "transferring"
        switch ((($BITS_ONGOING| Measure-Object).count)) { # HOW MANY ARE GOING RIGHT NOW
            {$_ -lt $QueueSize} { # IF IT'S LESS THAN THE QUEUE SIZE
                $StartedThisRound = ((Get-BitsTransfer | where DisplayName -like "$bitsfilter*"  | where jobstate -eq 'suspended' | select -first $($QueueSize-$_) | resume-bitstransfer -Asynchronous)| Measure-Object).Count
                if ($StartedThisRound -gt 0) { write-host "[$(get-date)] Files currently downloading: $($_).  Added $StartedThisRound files to queue." -ForegroundColor DarkCyan  }
            }
            $_ { # EVERY ITERATION 
                if ($_ -eq 0) { # IDLE
                    sleep 1;write-host '.' -NoNewline
                } else { # DL ONGOING
                    write-host "[$(get-date -Format 'HH:mm.ss_fff')] $($_)/$($QueueSize) active bitsdownload transfers" -ForegroundColor GREEN
                }
            }
        }
    
        if ((($BITS_ONGOING| Measure-Object).count) -eq 0) { # NOTHING TO DO?
            $ErrorOnes = Get-BitsTransfer | where DisplayName -like "$bitsfilter*" |where jobstate -eq 'error' # CLEAN UP THE QUEUE
            foreach ($Bad in $ErrorOnes) {
                if ($bad.errordescription -like "*404*") {
                    $bad.errordescription # WAS NUKED BETWEEN QUEUE BUILD AND FETCH.. FOILED AGAIN
                }
                    $bad|Remove-BitsTransfer # DEALING WITH GET-BITSTRANSFERS CAN GET SLOW AT LARGER VOLUMES
            }
        }
    }
    while ($true)
}

catch {
    "ERRORS: $($error.Count)"
    $error.fullyqualifiederrorid
}

finally {
    write-host "It's over." -ForegroundColor Yellow
}
