##############################################################################
# culture syphon module: bitstransfer queue jockey    cs_bitsqueue.ps1
##############################################################################
#
# maintains up to $queuesize downloads per loop iteration from the pool of
# suspended bitstransfers.
#
##############################################################################
 

# set the following to the drive letter of your download folder with trailing backslash
$bitsfilter = 'Y:\' # *** Requires trailing backslash - is used to lazily filter for only my bits jobs

[int64]$RunningTotal = 0
[int]$BITS_DONE_COUNT = 0
$QueueSize = 40
[version]$csyphon = [version]::new(1,0)
$banner = @"
     Culture Syphon BitsTransfer Queue Module $csyphon Activated
"@ 
try {
    write-host $Banner -foregroundcolor green
    do {
        $BITS_ONGOING = (Get-BitsTransfer -AllUsers | where DisplayName -like "$bitsfilter*")| where jobstate -eq "transferring"
        switch ((($BITS_ONGOING| Measure-Object).count)) { # HOW MANY ARE GOING RIGHT NOW
            {$_ -lt $QueueSize} { # IF IT'S LESS THAN THE QUEUE SIZE
                $StartedThisRound = ((Get-BitsTransfer | where DisplayName -like "$bitsfilter*"  | where jobstate -eq 'suspended' | select -first $($QueueSize-$_) | resume-bitstransfer -Asynchronous)| Measure-Object).Count
                if ($StartedThisRound -gt 0) { write-host "[$(get-date)] Files currently downloading: $($_).  Added $StartedThisRound files to queue." -ForegroundColor DarkCyan  }
            }
            $_ { # every iteration 
                if ($_ -eq 0) { sleep 1;write-host '.' -NoNewline } else {
                    write-host "[$(get-date -Format 'HH:mm.ss_fff')] $($_)/$($QueueSize) active bitsdownload transfers" -ForegroundColor Magenta
                }
            }
        }
    
        if ((($BITS_ONGOING| Measure-Object).count) -eq 0) {
            $ErrorOnes = Get-BitsTransfer | where DisplayName -like "$bitsfilter*" |where jobstate -eq 'error'
            foreach ($Bad in $ErrorOnes) {
                if ($bad.errordescription -like "*404*") {
                    $bad.errordescription
                    $bad|Remove-BitsTransfer
                }
            }
        }
    }
    while ($true)
}

catch {
    write-host "Error Count: $($error.Count). " -ForegroundColor Cyan
    '=[errors]='
    $Error.fullyqualifiederrorid
    write-host 'Check contents of variable $error for more details.' -foregroundcolor yellow
}

finally {

}
