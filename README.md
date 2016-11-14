# culsyph
gotta get your culture syphoned, guy

this suite of scripts will efficiently rape the hell out of any supplied imageboard @ 4C, and build a similar folder structure to the live data so you can continue to rape culture in the future and resume existing threads.  deleted files will be re-downloaded the next time it finds them.  or point it to your favourite board and leave it running 24/7 and be the first kid on your block to have 0 minute dick pics if that's your thing (and you know it's your thing).

forgive the spaghetti code in places as this was written spanning my various levels of powershell knowledge. it taught me a lot!

INSTRUCTIONS:

1: you need to modify the $StorageRoot variable (download path) to cs_syphon.ps1 as $StorageRoot ($StorageRoot = 'Y:\Mecha\mpl_trimmed')

2: you need to modify the $BitsFilter variable in cs_diskwrite.ps1 and cs_bitsqueue.ps1 to match the root of the path you just set in step 1 ($BitsFilter = 'Y:\')

3: run launch.cmd > opens 3 instances of powershell, one for each role - the cmd.exe windows stay open when you control+c to break out of the running script when you're done

4: that is all I think.  provide feedback and I'll get to it.


I'm not malicious I'm just a leech - I'm sharing this because I think it works pretty good.
