##############################################################################
# culture syphon module: disk write | cs_diskwrite
##############################################################################
# this script takes the existing bits jobs that have finished 
#   and writes them to disk (in an aggressive manner)
#
# * this has no throttle and will write all successful bitstransfers to disk in large batches
# because of this it may look like it's not doing anything.  it's not hung it's busy being a pig
#
# if you want to throttle writes, turn down the throttle of the bits queue
#   via the 'culture syphon module: bitstransfer queue jockey' (cs_bitsqueue.ps1)
#
##############################################################################

# CONFIGURABLE SETTINGS

# set the following to the drive letter of your download folder with trailing backslash
$bitsfilter = 'Y:\' # *** Requires trailing backslash - is used to lazily filter for only my bits jobs

# set to name of your network adapter in ncpa.cpl / network connections 
$netname = 'Ethernet' # used for bandwidth stats per loop

#
$TimeBetweenRounds = 1 * 60 # this is a value in seconds to rest between iterations of writing to disk

# STATIC SETTINGS
# everything below here should work without you having to adjust anything but have fun and 
# this started as a fun way for me to basically learn regex.. then I saw it working and kept going
[int64]$RunningTotal = 0
[int]$BITS_DONE_COUNT = 0
[version]$csyphon = [version]::new(1,0)
$banner = @"
     Culture Syphon Disk Write Module $csyphon Activated
"@
cls
try {
    write-host $banner -foregroundcolor green
    $StartBytes = ((Get-NetAdapterStatistics -Name $netname).ReceivedBytes)
    $LastBytes = ((Get-NetAdapterStatistics -Name $netname).ReceivedBytes)
    $lcount = 1 # loop iterator 
    $fcount = 1 # file iterator   
    do {
        $BITS_ALL = (Get-BitsTransfer -AllUsers | where DisplayName -like "$bitsfilter*"| where jobstate -ne "error")
        $BITS_QUEUED = (($BITS_ALL | where jobstate -eq 'Queued').count)
        $BITS_DONE = ($BITS_ALL | where jobstate -eq 'Transferred') #(Get-BitsTransfer -AllUsers | where jobstate -eq 'Transferred')
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

}
