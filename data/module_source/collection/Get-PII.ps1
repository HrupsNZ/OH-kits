<#
.Synopsis
   Parses PII data from given Word/Excel document and returns the first few characters of data. Regex values can be changed to catch different data.
   Authors: @utkusen, gozdesinturk
.DESCRIPTION
   Long description
.EXAMPLE
   Get-PII.ps1 "C:\Path\To\File.docx"
.EXAMPLE
   Get-PII.ps1 "C:\Path\to\File.xlsx"
.INPUTS
   The only input parameter is the Path to the xls (xlsx) or doc (docx) file
.OUTPUTS
   The Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   
.FUNCTIONALITY
   Takes a file (xls or doc) and check if it matches some regex expressions.
#>

$global:ScriptLocation = $(get-location).Path
$Global:MaxRowToSearch= 10

#region RegeXes
$global:MastercardRE= '5[1-5][0-9]{14}'
$global:AmexCardRE= '3[47][0-9]{13}'
$global:MaestroCardRE ="(5018|5020|5038|6304|6759|6761|6763)[0-9]{8,15}"
$global:SSNRE = "(\d{3}-?\d{2}-?\d{4}|XXX-XX-XXXX)"
$global:TCKimlikNoRE = "[1-9]{1}[0-9]{10}"
$global:PassportRE = "(?!^0+$)[a-zA-Z0-9]{3,20}"
$global:DateofBirth ="(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]))\1|(?:(?:29|30)(\/|-|\.)(?:0?[1,3-9]|1[0-2])\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)0?2\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9])|(?:1[0-2]))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})"
$global:IPaddress ="((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
#Endregion

#region Functions
function release-comobject($ref) {
  while ([System.Runtime.InteropServices.Marshal]::ReleaseComObject($ref) -gt 0) { }
  [System.GC]::Collect()
}

function Check-Regex{
    [CmdletBinding()]
    [Alias("cr")]
    Param(
        [Parameter(Position=0,Mandatory=$true, ValueFromPipeline=$true )] [ValidateNotNull()]$InputString
    )

    Begin{
        #$regexx = new-object System.Text.RegularExpressions.Regex( $Regex,[System.Text.RegularExpressions.RegexOptions]::MultiLine)
    }
    Process
    {
        [System.Text.RegularExpressions.MatchCollection] $MMasterCard = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:MastercardRE)
        [System.Text.RegularExpressions.MatchCollection] $MAmexCard   = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:AmexCardRE)
        [System.Text.RegularExpressions.MatchCollection] $MMaestroCard= [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:MaestroCardRE)
        [System.Text.RegularExpressions.MatchCollection] $MSSN        = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:SSNRE)
        [System.Text.RegularExpressions.MatchCollection] $MTCK        = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:TCKimlikNoRE)
        [System.Text.RegularExpressions.MatchCollection] $MPassport   = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:PassportRE)
        [System.Text.RegularExpressions.MatchCollection] $MDateofBirth= [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:DateofBirth)
        [System.Text.RegularExpressions.MatchCollection] $MIPAddress  = [System.Text.RegularExpressions.Regex]::Matches($InputString,$global:IPaddress)
    }
    End{
    #Credit card pattern found: 5533*****) 
        if($MMasterCard.Count -gt 0){
            foreach($match in $MMasterCard){
                " "                                                 #5228.196633676704                 
                "Master Card Match found $($match.Value.Substring(1,4))-xxxxxxxxxxxx"
            }
        }
        if($MAmexCard.Count -gt 0){
            foreach($match in $MAmexCard){  
                " "                                                    #3726.07003254293
                "Amex Card Match found $($match.Value.Substring(1,4))-xxxxxxxxxxx"
            }
        }
        if($MMaestroCard.Count -gt 0){
            foreach($match in $MMaestroCard){
                " "
                "Maestro Card Match found $($match.Value.Substring(1,4))-xxxxxxxxx"
            }
        }
        if($MSSN.Count -gt 0){
            foreach($match in $MSSN){
                " "
                "SSN number Match found $($match.Value.Substring(1,4))-xxxxxxxxx"
            }
        }
        if($MTCK.Count -gt 0){
            foreach($match in $MTCK){
                " "
                "TCK Number Match found $($match.Value.Substring(1,4))-xxxxxxxxx"
            }
        }
        if($PassportRE -gt 0){
            foreach($match in $MPassport){
                " "
                "Passport Match found $($match.Value.Substring(1,4))-xxxxxxxxx"
            }
        }
        if($MDateofBirth.Count -gt 0){
            foreach($match in $MDateofBirth){
                " "
                "Date of Birth Match found $($match.Value.Substring(1,2))-xxxxxxxxx"
            }
        }
        if($MIPAddress.Count -gt 0){
            foreach($match in $MIPAddress){
                $ma=[string]$match.value
                $text= $ma.Split('.')[0]
                " "
                "Ip Address Match found $text.xxx.xxx.xxx"
            }
        }
    
    }
}
function Use-DocumentLogic{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)] $FilePath
    )
    begin{}
    process{
        try{
            $Word = New-Object -ComObject Word.Application
            $Document = $Word.Documents.Open($FilePath)
            $allsb = New-object System.Text.StringBuilder 
            
            $Document.Paragraphs | ForEach-Object {
                $allsb.AppendLine($_.Range.Text)| Out-Null
            }

            [string]$TextVar = $allsb.ToString() 
            Check-Regex -InputString $TextVar
        }
        catch{
            if(!($Word)){
               
                 "Error Message: $($_.Exception.Message)"
            }
            else{
                 $Document.Close()
                 $word.Quit()
                 [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Word) | Out-Null
            }
        }
    }
    end{
         #Close Document
         $Document.Close()
         #Quit word
         $Word.Quit()
         #Release Com Object
         release-comobject $Word
         Get-Process | where{ $_.Name -match "Word" -or $_.Name -match "Excel"} | Stop-Process
    }
}

function LoadData{
	[Cmdletbinding()]
	param(
		[Parameter(mandatory=$true,position=0)]$WorkSheet  #Worksheet com object.
	)
	BEGIN{
		$WSname= $WorkSheet.Name
	}
	PROCESS{
        #Row Columns (Matrix MaxRowToSearch x MaxRowToSearch
        [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
        
		for($row = 1; $row -lt $Global:MaxRowToSearch; $row++){
            for($column=1; $column -lt $Global:MaxRowToSearch; $column++){
                if(!([string]::IsNullOrEmpty($WorkSheet.Cells.Item($row,$column).Text))){
                    $sb.AppendLine($WorkSheet.Cells.Item($row,$column).Text) | Out-Null
                }
                #Write-host "Working row:$row/Column:$column"
            }
        }
	}
	END{
		return $sb.ToString()
	}
}
function ReadDataInSpreadSheets{
	[Cmdletbinding()]
	param(
			[Parameter(mandatory=$true,position=0)]$WorksheetsInBook
	)
	BEGIN{
		$outputArray = @()
	}
	PROCESS{
		$j=$WorksheetsInBook.Count
		foreach($item in $WorksheetsInBook){
			$WSname= $WorkSheet.Name
			$i++;

			#Open the workbook Itself
			$WorkSheet = $WorkBook.sheets.item($item)
			#Activate the Current worksheet
			$WorkSheet.Activate() | Out-Null

			#Load the data in the spreadsheet and convert it to an array of classes in the $releasemetricsarray.(All items)
			$StringOnWorkSheet= LoadData $WorkSheet
            if($StringOnWorkSheet){
                $outputArray+=$StringOnWorkSheet
            }
		}
	}
	END{
	 return $outputArray
	}
}
function Use-ExcelLogic{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)] $FilePath
    )
    begin{
    }
    process{
        try{
           
            $ExcelComObj = New-Object -ComObject Excel.Application
            # Disable the 'visible' property so the document won't open in excel
            #$ExcelComObj.visible = $true
            $ExcelComObj.visible = $false
            
            # Open the Excel file and save it in $WorkBook
            $WorkBook = $ExcelComObj.Workbooks.Open($FilePath)
            
            #Get All WorkSheets in the Book
            $WorkSheetsName=@()
            foreach($item in $workBook.Worksheets){
            	$WorkSheetsName+=$item.Name
            }
            
            [string]$TextVar = ReadDataInSpreadSheets $WorkSheetsName
            Check-Regex -InputString $TextVar
        
            #Close Worksheet
            $WorkBook.close()
            #Quit Excel
            $ExcelComObj.Quit()
        }
        catch{
            if(!($ExcelComObj)){
                 "Error Message: $($_.Exception.Message)"
            }
            else{
                 $ExcelComObj.Quit()
                 while( [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelComObj)){}
            }
        }
        #    "File doesn't Exists '$FilePath'"
    }
    end{
        #Release Com Object
        release-comobject $ExcelComObj
        Get-Process | where{ $_.Name -match "Word" -or $_.Name -match "Excel"} | Stop-Process
    }
}

#endregion

#start Script

try{
    if(!(Test-Path $FilePath)){
        Write-Error -Message "The file ""$FilePath"" doesn't exists"
    }
    
    [System.IO.FileInfo]$fi = New-Object System.IO.FileInfo -ArgumentList $FilePath
    if($fi.Extension -match "xls"){
        Use-ExcelLogic $FilePath
    }
    else{
        Use-DocumentLogic $FilePath
    }
}
catch{
    "There was an error with the script. Error: $($_.Exception.Message)"
}







