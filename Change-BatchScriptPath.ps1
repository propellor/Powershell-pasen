<#
.SYNOPSIS
Search andr Replaces content in text files like path in bat files.
.DESCRIPTION
All files in a directory and its subdirectories will be search after a reg expression and get that replaced. 
.EXAMPLE
 runs .\Change-BatchScriptPath.ps1 -dir c:\batfiles -OldRegExp "badtext" -newstring "bettertext"
.EXAMPLE
Pipe directory "c:\batfiles" | .\Change-BatchScriptPath.ps1 -OldRegExp "d:\\" -newstring "f:\\engineroom"
.EXAMPLE
Only change powershell script files "c:\scripts" | .\Change-BatchScriptPath.ps1 -old "d:\\" -new "f:\\engineroom" -filter "ps1"

.EXAMPLE
Pipe directory and user order of parameters "c:\scripts" | .\Change-BatchScriptPath.ps1 "txt"  "badtext" "goodtext"

.PARAMETER Dir
The full path to the directory where all the text files are. Eg T:\goodstuff\batsorun .  Can also be piped into the script.
.PARAMETER Filter
What files should be checked. Default bat files.
.PARAMETER OldRegExp
What regular expression to search for. Alias old
.PARAMETER NewString
what it should be replaced with . Alias new
latest version
http://github.com/patriklindstrom/Powershell-pasen
.LINK
About Author and script
http://www.lcube.se
.LINK
Regular Expression Tutorial
http://www.regular-expressions.info/tutorial.html
.NOTES
    File Name  : Change-BatchScript.ps1 
    Author     : Patrik Lindström LCube
#>
param  
(  
    [Parameter(
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [string]$Dir , 
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('f')] 
    [string]$Filter="bat" , 
        [Parameter(
        Position=2, 
        Mandatory=$true, 
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('old')] 
    [string]$OldRegExp , 
    [Parameter(
        Position=3, 
        Mandatory=$true, 
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('new')] 
    [string]$NewString
) 
   # Test for existence of bat directory path  
   if (!$Dir)  
   {  
        $(Throw 'Missing argument: Dir')    
   }  
  if (-not $Dir.EndsWith("\"))  
    { 
        $Dir += "\" 
    }     
    if (!(test-path $Dir))  
    { 
         $(Throw "The Dir: $Dir does not exist")    
    }

# Set batfilerna så att man kan skriva till dem. Kan vara show stopper
$Dir | gci -r  -fi *.$Filter | % { if($_.IsReadOnly){$_.IsReadOnly= $false} }
# Lista batfilerna att de har status not readonly helt onödigt men kul
#  $Dir | gci -r  -fi *.$Filter  | select fullname,isreadonly
# Byt ut 'Tieto Ftp' och 'TietoFtp' mot nytt namn. The main thing
$Dir | gci  -r  -fi *.$Filter  | % { $(gc $_.FullName) -replace $OldRegExp, $NewString| sc $_.FullName }
# Tada lista dem. helt onödigt
$Dir | gci  -r  -fi *.$Filter  | gc