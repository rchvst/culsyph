##############################################################################
# cs_diskwrite.ps1 | culture syphon module: disk write
##############################################################################
#
#    if you want to throttle writes, slow down your bits queue via cs_bitsqueue.ps1
#
#    writes all pending completed bitstransfers to disk
#    bitstransfers are stored as temporary files until you 'complete-bitstransfer' them
#    this offers you the flexibility to commit nothing to disk until you want to
#    this may be handy if your IO is limited
#    recommended behavior is to just let it loop and adjust $TimeBetweenRounds to your delight
#
##############################################################################

# YOU NEED TO SET AT LEAST THE BITSFILTER TO YOUR DOWNLOAD PATH IN ALL THREE FILES
# set the following to the drive letter of your download folder with trailing backslash
$bitsfilter = 'Y:\' # *** Requires trailing backslash - is used to lazily filter for only my bits jobs
# for example my $StorageRoot is 'Y:\mecha\mpl_trimmed' in cs_syphon so I used 'y:\' for $bitsfilter

$netname = 'Ethernet' # set to name of your network adapter in ncpa.cpl / network connections 
$TimeBetweenRounds = 1 * 60 # this is a value in seconds to rest between iterations of writing to disk

# should not need to change but hack away
[int64]$RunningTotal = 0
[int]$BITS_DONE_COUNT = 0
[version]$csyphon = [version]::new(1,0)
$banner = @"
     cs_diskwrite.ps1 | Disk Write Module $csyphon Activated
"@
cls
try {
    write-host $banner -foregroundcolor green
    $StartBytes = ((Get-NetAdapterStatistics -Name $netname).ReceivedBytes)
    $LastBytes = ((Get-NetAdapterStatistics -Name $netname).ReceivedBytes)
    $lcount = 1 # loop iterator 
    $fcount = 1 # file iterator   
    do {
        $BITS_ALL = (Get-BitsTransfer | where DisplayName -like "$bitsfilter*"| where jobstate -ne "error")
        $BITS_QUEUED = (($BITS_ALL | where jobstate -eq 'Queued').count)
        $BITS_DONE = ($BITS_ALL | where jobstate -eq 'Transferred') #(Get-BitsTransfer  | where jobstate -eq 'Transferred')
        $BITS_DONE_COUNT = ($BITS_DONE.count)
        $CurrentBytes = ((Get-NetAdapterStatistics -Name $netname).ReceivedBytes)
        $Diff = "{0:N0}" -f (($CurrentBytes - $LastBytes)/1kb)
        $Now = "{0:N0}" -f (($CurrentBytes)/1kb)

        # COMPLETED DOWNLOADS     
        if ($BITS_DONE_COUNT -ge 1) {  
            "-------($(Get-date)------------"
            $RunningTotal += $BITS_DONE_COUNT
            $DiffAvg = "{0:N0}" -f ($diff/$BITS_DONE_COUNT)
            $BITS_DONE | % { 
                
                "$fcount $($_.filelist.localname)"
                $fcount++
                $_|Complete-BitsTransfer
            }
            " ^ writing these files during this iteration"
            write-host "[$(get-date)] Preserving $BITS_DONE_COUNT files [$($Diff)kb/~$($DiffAvg)kb each] to disk.  That's a total of $RunningTotal items saved ... $(($BITS_ALL.count -$BITS_DONE_COUNT)) files remain to be downloaded." #$((get-BitsTransfer -AllUsers | where Jobstate -eq ).count) to go m'Lord."
            #$BITS_DONE | Complete-BitsTransfer
   
        } else { # JOBSTATE -NE 'transferred'
           write-host "[$(get-date)] Idle, so I'm sleeping, (0 completed transfers to save); Network Stats: Since Last reboot: $($now)kb // Since Last Iteration: +$($diff)kb"
           Start-Sleep -Seconds $TimeBetweenRounds
        }
        sleep -Milliseconds 50
        $lcount++
    }
    while ($true)
}
catch { 

}

finally {
     write-host "It's Over.  Grats on another $RunningTotal files saved this run."
}
