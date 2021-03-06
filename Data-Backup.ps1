<# 
.SYNOPSIS 
Script mirrors two directories. It can then make changes to specific files eg endpoint could be different. Defaults localhost as MasterServer.
.DESCRIPTION 
In a loadbalanced IIS envirement you make changes to one IIS node. You then have to make sure that the other IIS nodes get the same
binaries and configs. This script uses robocopy to sync them. Some directories and types of files like log files you want to omit.
Sometimes the service endpoints in the nodes are different NodeA might get its WCF endpoints from NodeA and NodeB get its endpoints from
NodeB. The script can then if flag for DoPostReplace is set to true fix this after the robocopy mirroring.
.EXAMPLE 
 Simple run c:\scripts\sync-webnodes.ps1    -SlaveServer wsp0739c 
.EXAMPLE 
Fix thing after mirror. Like endopoints references and send SlaveServerList as pipe: "wsp0740c" | .\sync-webnodes.ps1   -SlaveServer wsp0739c -DoPostReplace $TRUE

.PARAMETER SlaveServerList 
List of  computername that should have copy of the MasterServer. Can be single like servername "wsp0739c"
.PARAMETER MasterServer 
A computername that is the MasterServer where everything should be copied from. Eg "wsp0739c". It is defaulted to the name of the computer it runs on.

.PARAMETER SkipDirectories 
A list of Directories that should be omitted from the synchronies. Could be a backupdirectory.

.PARAMETER SkipFiles 
A list file patterns that should be skipped. Could be *.log. Is defaulted to: '"alive.htm" "*.log"' 

.PARAMETER DoPostReplace 
Is default $FALSE. If true then there is a grep liked replacement of files. Could be if there are webconfig files with endpoints that should be different between nodes. Could also be databaseconnection strings. Change in script if you want new pattern

.PARAMETER PostReplaceFilePatternList    
List of files most  probably web.config files. Is defaulted to  "TCM_Client\Web.config". There is also a hardcoded filter set to *.config that will affect what would be run.


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
    [Alias('slave')] 
    [Alias('new')] 
    [Alias('s')] 
    $SlaveServerList  ,

    [Parameter( 
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$false, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('master')] 
    [Alias('original')] 
    [Alias('m')] 
   [string] $MasterServer ,
    

    
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
    $PostReplaceFilePatternList = "TCM_Client\Web.config"    

)
if (! $MasterServer ) { $MasterServer = get-content env:computername }
$MasterDir = "\\$MasterServer\d$\inetpub\wwwroot"
if (!(test-path $MasterDir)) { $(Throw "The MasterDir: $MasterDir does not exist") }

foreach ($SlaveServer in $SlaveServerList) {
    $SlaveDir = "\\$SlaveServer\d$\inetpub\wwwroot"
    if (!(test-path $SlaveDir))  {  $(Throw "The SlaveDir: $SlaveDir does not exist") }
    Write-Verbose "Start Robocopy mirroring between Master:$MasterDir and $SlaveDir "
    Write-Verbose "Skipping directories $SkipDirectories  "
    Write-Verbose "Skipping files $SkipFiles  "
    robocopy $MasterDir $SlaveDir /MIR /XD $SkipDirectories /XF $SkipFiles

    Write-Verbose "Done Robocopy Mirroring for $SlaveDir"


    if ($DoPostReplace)
        { 
            #Only search and replace in *.config files . Change this if neccesary
            $Filter = "config"
            $PostReplaceFileList = @("$SlaveDir\$PostReplaceFilePatternList")               
            Write-Verbose "Starting special post mirror replace."
            $OldRegExp = '(?i)(<endpoint address="http://)(\w*?)(\.|:.*>)'            
    # Explaination of Regulare expression in $OldRegExp
    #  (<endpoint address="http://)(\w*?)(\.|:.*>)
    # Options: case insensitive
    # Get the Head
    #    Match the characters “<endpoint address="http://” literally «<endpoint address="http:// and put into backref $1
    # Get the Body
    #    Match a single character that is a “word character” (letters, digits, and underscores) «\w*?» and put into backref $2
    #      Continue to match, as few times as possible, expanding as needed (lazy) «*?»
    #       Match the character “.” literally «\.»    Or  the character “:” 
    # Get the Tail of the line
    #       Match any single character that is not a line break character «.*»
    #          Between zero and unlimited times, as many times as possible, giving back as needed (greedy) «*»
    #       Match the character “>” literally «>» and put all
            Write-Verbose "Finding and replacing things like this reg expr $OldRegExp"
            $NewString = '$1' + $SlaveServer + '$3'
            Write-Verbose "In these places: $PostReplaceFileList with filter *.$Filter"
            
            $PostReplaceFileList | gci  -r  -fi *.$Filter  | % { 
                                                                if (!(test-path $_.FullName))  { $(Throw "The PostReplaceFile: $_.FullName does not exist")  }
                                                                $(gc $_.FullName) -creplace $OldRegExp, $NewString| sc $_.FullName 
                                                                }
        }

} # End Major for each loop - per Slave Server
Write-Verbose "Done Syncing webnodes"