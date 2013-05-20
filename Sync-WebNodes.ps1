<# 
.SYNOPSIS 
short 
.DESCRIPTION 
descrobe what it does
.EXAMPLE 
 Simple run .\sync-webnodes.ps1 -MasterServer wsp0739c  -SlaveServer wsp0740c 
.EXAMPLE 
Fix thing after mirror. Like endopoints references and pipe wsp0739c | .\sync-webnodes.ps1   -SlaveServer wsp0740c -DoPostReplace $TRUE

.PARAMETER MasterServer 


.PARAMETER SlaveServer 




.PARAMETER SkipDirectories 


.PARAMETER SkipFiles 


.PARAMETER DoPostReplace 

.PARAMETER PostReplaceFileList 


.LINK 
latest version 
http://github.com/patriklindstrom/Powershell-pasen 
.LINK 
About Author and script 
http://www.lcube.se 
.LINK 
About powershell for SQL Server 
http://msdn.microsoft.com/en-us/library/hh245198.aspx 
.NOTES 
    File Name  : Sync-WebNodes.ps1 
    Author     : Patrik Lindström LCube 
    Requires   : PowerShell V2 CTP3 


#> 

param  
(  
    [Parameter( 
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('master')] 
    [Alias('original')] 
    [Alias('m')] 
    [string]$MasterServer = "wsp0739c" ,
    
    [Parameter( 
        Position=1, 
        Mandatory=$true, 
        ValueFromPipeline=$false, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('slave')] 
    [Alias('new')] 
    [Alias('s')] 
    [string]$SlaveServer = "wsp0740c" ,
    
   [Parameter( 
        Position=2, 
        Mandatory=$false) 
    ] 
    [Alias('skipdir')] 
    [string]$SkipDirectories = "archive" ,
    
   [Parameter( 
        Position=3, 
        Mandatory=$false) 
    ] 
    [Alias('noinclude')] 
    [Alias('skip')] 
    [string]$SkipFiles = '"alive.htm" "*.log"' ,
    
    [Parameter( 
        Position=4, 
        Mandatory=$false) 
    ] 
    [Alias('post')] 
    [Alias('p')]     
    [boolean] $DoPostReplace = $false    ,
    
    [Parameter( 
        Position=5, 
        Mandatory=$false) 
    ] 
    [Alias('postfiles')] 
    [Alias('pf')]      
    $PostReplaceFileList = "D:\inetpub\wwwroot\TCM_Client\Web.config"    

)

$MasterDir = "\\$MasterServer\d$\inetpub\wwwroot"

$SlaveDir = "\\$SlaveServer\d$\inetpub\wwwroot"

Write-Verbose "Start Robocopy mirroring between Master:$MasterDir and $SlaveDir "
Write-Verbose "Skipping directories $SkipDirectories  "
Write-Verbose "Skipping files $SkipFiles  "
robocopy $MasterDir $SlaveDir /MIR /XD $SkipDirectories /XF $SkipFiles

# (<endpoint address="http://)(\w*?)(\.|:.*>)
# 
# Options: case insensitive
# 
# Match the regular expression below and capture its match into backreference number 1 «(<endpoint address="http://)»
#    Match the characters “<endpoint address="http://” literally «<endpoint address="http://»
# Match the regular expression below and capture its match into backreference number 2 «(\w*?)»
#    Match a single character that is a “word character” (letters, digits, and underscores) «\w*?»
#       Between zero and unlimited times, as few times as possible, expanding as needed (lazy) «*?»
# Match the regular expression below and capture its match into backreference number 3 «(\.|:.*>)»
#    Match either the regular expression below (attempting the next alternative only if this one fails) «\.»
#       Match the character “.” literally «\.»
#    Or match regular expression number 2 below (the entire group fails if this one fails to match) «:.*>»
#       Match the character “:” literally «:»
#       Match any single character that is not a line break character «.*»
#          Between zero and unlimited times, as many times as possible, giving back as needed (greedy) «*»
#       Match the character “>” literally «>»
Write-Verbose "Done Robocopy Mirroring"


if ($DoPostReplace)
    {
        Write-Verbose "Starting special post mirror replace."
        $OldRegExp = '(?i)(<endpoint address="http://)(\w*?)(\.|:.*>)'
        Write-Verbose "Finding and replacing things like this reg expr $OldRegExp"
        $NewString = '$1' + $SlaveServer + '$3'
        Write-Verbose "In these places: $PostReplaceFileList"
        $PostReplaceFileList | gci  -r  -fi *.$Filter  | % { $(gc $_.FullName) -creplace $OldRegExp, $NewString| sc $_.FullName }
    }

Write-Verbose "Done Syncing webnodes"