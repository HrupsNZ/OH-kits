#   This file is part of Invoke-Obfuscation.
#
#   Copyright 2017 Daniel Bohannon <@danielhbohannon>
#         while at Mandiant <http://www.mandiant.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.



Function Out-EncodedBXORCommand
{
<#
.SYNOPSIS

Generates BXOR (bitwise XOR) encoded payload for a PowerShell command or script. Optionally it adds command line output to final command.

Invoke-Obfuscation Function: Out-EncodedBXORCommand
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None

.DESCRIPTION

Out-EncodedBXORCommand encodes an input PowerShell scriptblock or path as an bitwise XOR'd payload. It randomly chooses between .Split/-Split/array syntax to store the encoded payload in the final output. The purpose is to highlight to the Blue Team that there are more novel ways to encode a PowerShell command other than the most common Base64 approach.

.PARAMETER ScriptBlock

Specifies a scriptblock containing your payload.

.PARAMETER Path

Specifies the path to your payload.

.PARAMETER NoExit

Outputs the option to not exit after running startup commands.

.PARAMETER NoProfile

Outputs the option to not load the Windows PowerShell profile.

.PARAMETER NonInteractive

Outputs the option to not present an interactive prompt to the user.

.PARAMETER NoLogo

Outputs the option to not present the logo to the user.

.PARAMETER Wow64

Calls the x86 (Wow64) version of PowerShell on x86_64 Windows installations.

.PARAMETER Command

Outputs the option to execute the specified commands (and any parameters) as though they were typed at the Windows PowerShell command prompt.

.PARAMETER WindowStyle

Outputs the option to set the window style to Normal, Minimized, Maximized or Hidden.

.PARAMETER ExecutionPolicy

Outputs the option to set the default execution policy for the current session.

.PARAMETER PassThru

(Optional) Avoids applying final command line syntax if you want to apply more obfuscation functions (or a different launcher function) to the final output.

.EXAMPLE

C:\PS> Out-EncodedBXORCommand -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -NoProfile -NonInteractive

powershell  -NoProfil -NonInter     "((97,68 ,95 ,66,83 , 27 , 126, 89 , 69 , 66 ,22 ,17 , 126,83,90 , 90 ,89,22 , 97,89, 68 ,90 ,82 , 23 , 17 ,22 , 27 , 112, 89 ,68, 83 , 81,68 , 89,67 ,88 , 82 ,117, 89 , 90,89, 68 , 22 ,113,68 , 83,8
3 ,88,13 , 22,97,68 , 95,66 , 83,27 ,126,89 , 69 , 66 , 22 , 17 , 121,84, 80, 67 ,69,85,87, 66,95, 89, 88 , 22, 100 ,89, 85, 93 , 69, 23, 17 ,22,27 , 112,89 ,68 ,83 ,81 , 68 , 89, 67, 88 ,82,117, 89,90 , 89, 68,22 ,113,68, 83 , 83,88 )
| fOREACh-objEct{[ChAR]($_ -bxoR'0x36' )} )-jOIn'' | InVOKE-ExpressIon"

C:\PS> Out-EncodedBXORCommand -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -NoProfile -NonInteractive -PassThru

( ( 180,145 , 138 ,151, 134, 206 ,171 , 140, 144 ,151 , 195 ,196 , 171 ,134, 143 ,143,140 , 195 ,180, 140 , 145 ,143,135 , 194,196 , 195, 206, 165,140 ,145,134,132,145,140 , 150 ,141, 135 , 160, 140 ,143 , 140 ,145 , 195,164,145 , 134
, 134 , 141 ,216 ,195 ,180 ,145 ,138, 151 ,134 ,206, 171,140 , 144 ,151,195 ,196,172,129 ,133 ,150,144 , 128 ,130 ,151 ,138,140 ,141 , 195 , 177,140,128,136 , 144 , 194, 196 ,195,206,165 , 140 , 145,134,132, 145 ,140 ,150 ,141,135 , 16
0 , 140, 143, 140 , 145 ,195 ,164 ,145,134 , 134, 141) | fOrEAch-ObJect {[chaR] ( $_-BXor 0xE3 ) } )-jOIN'' | iEx

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding(DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Switch]
        $NoExit,

        [Switch]
        $NoProfile,

        [Switch]
        $NonInteractive,

        [Switch]
        $NoLogo,

        [Switch]
        $Wow64,

        [Switch]
        $Command,

        [ValidateSet('Normal', 'Minimized', 'Maximized', 'Hidden')]
        [String]
        $WindowStyle,

        [ValidateSet('Bypass', 'Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted')]
        [String]
        $ExecutionPolicy,

        [Switch]
        $PassThru
    )

    # Either convert ScriptBlock to a String or convert script at $Path to a String.
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    # Create list of random delimiters $RandomDelimiters.
    # Avoid using . * ' " [ ] ( ) etc. as delimiters as these will cause problems in the -Split command syntax.
    $RandomDelimiters  = @('_','-',',','{','}','~','!','@','%','&','<','>')

    # Add letters a-z with random case to $RandomDelimiters.
    @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z') | ForEach-Object {$UpperLowerChar = $_; If(((Get-Random -Input @(1..2))-1 -eq 0)) {$UpperLowerChar = $UpperLowerChar.ToUpper()} $RandomDelimiters += $UpperLowerChar}

    # Only use a subset of current delimiters to randomize what you see in every iteration of this script's output.
    $RandomDelimiters = (Get-Random -Input $RandomDelimiters -Count ($RandomDelimiters.Count/4))

    # Generate random hex value for BXOR. Keep from 0x00 to 0x5F to avoid character representations on the command line that are unsupported by PowerShell.
    $HexDigitRange = @(0,1,2,3,4,5,6,7,8,9,'a','A','b','B','c','C','d','D','e','E','f','F')
    $BXORValue  = '0x' + (Get-Random -Input @(0..5)) + (Get-Random -Input $HexDigitRange)

    # Convert $ScriptString to delimited and BXOR'd ASCII values in [Char] array separated by random delimiter from defined list $RandomDelimiters.
    $DelimitedEncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {$DelimitedEncodedArray += ([String]([Int][Char]$_ -BXOR $BXORValue) + (Get-Random -Input $RandomDelimiters))}

    # Remove trailing delimiter from $DelimitedEncodedArray.
    $DelimitedEncodedArray = $DelimitedEncodedArray.SubString(0,$DelimitedEncodedArray.Length-1)

    # Create printable version of $RandomDelimiters in random order to be used by final command.
    $RandomDelimitersToPrint = (Get-Random -Input $RandomDelimiters -Count $RandomDelimiters.Length) -Join ''

    # Generate random case versions for necessary operations.
    $ForEachObject = Get-Random -Input @('ForEach','ForEach-Object','%')
    $StrJoin       = ([Char[]]'[String]::Join' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $StrStr        = ([Char[]]'[String]'       | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Join          = ([Char[]]'-Join'          | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $BXOR          = ([Char[]]'-BXOR'          | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $CharStr       = ([Char[]]'Char'           | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Int           = ([Char[]]'Int'            | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ForEachObject = ([Char[]]$ForEachObject   | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    # Create printable version of $RandomDelimiters in random order to be used by final command specifically for -Split syntax.
    $RandomDelimitersToPrintForDashSplit = ''
    ForEach($RandomDelimiter in $RandomDelimiters)
    {
        # Random case 'split' string.
        If($ScriptString.Contains('^'))
        {
            $Split = ([Char[]]'Split' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
            $RandomDelimitersToPrintForDashSplit += '(' + (Get-Random -Input @('-Replace','-CReplace')) + " '^','' -$Split" + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimiter + "'" + ' '*(Get-Random -Input @(0,1))
            $Split = ([Char[]]"Replace('^','').Split" | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
        }
        Else
        {
            $Split = ([Char[]]'Split' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
            $RandomDelimitersToPrintForDashSplit += ('-' + $Split + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimiter + "'" + ' '*(Get-Random -Input @(0,1)))
        }

        # Randomize case of full syntax from above If/Else block.
        $Split = ([Char[]]$Split | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
        $RandomDelimitersToPrintForDashSplit = ([Char[]]$RandomDelimitersToPrintForDashSplit | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    }
    $RandomDelimitersToPrintForDashSplit = $RandomDelimitersToPrintForDashSplit.Trim()

    # Perform BXOR operation on $ScriptString.
    $EncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {$EncodedArray += ([String]([Int][Char]$_ -BXOR $BXORValue)) + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1))}

    # Remove trailing comma from $EncodedArray.
    $EncodedArray = ('(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray.Trim().Trim(',') + ')')

    # Generate random syntax to create/set OFS variable ($OFS is the Output Field Separator automatic variable).
    # Using Set-Item and Set-Variable/SV/SET syntax. Not using New-Item in case OFS variable already exists.
    # If the OFS variable did exists then we could use even more syntax: $varname, Set-Variable/SV, Set-Item/SET, Get-Variable/GV/Variable, Get-ChildItem/GCI/ChildItem/Dir/Ls
    # For more info: https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_automatic_variables
    $SetOfsVarSyntax      = @()
    $SetOfsVarSyntax     += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVarSyntax     += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVar            = (Get-Random -Input $SetOfsVarSyntax)

    $SetOfsVarBackSyntax  = @()
    $SetOfsVarBackSyntax += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBackSyntax += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBack        = (Get-Random -Input $SetOfsVarBackSyntax)

    # Randomize case of $SetOfsVar and $SetOfsVarBack.
    $SetOfsVar            = ([Char[]]$SetOfsVar     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SetOfsVarBack        = ([Char[]]$SetOfsVarBack | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    # Generator BXOR syntax with randomly-chosen quotes.
    $Quotes = Get-Random -Input @('"',"'",' ')
    $BXORSyntax = $BXOR + ' '*(Get-Random -Input @(0,1)) + $Quotes + $BXORValue + $Quotes
    $BXORConversion = '{' + ' '*(Get-Random -Input @(0,1)) + "[$CharStr]" + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + '$_' + ' '*(Get-Random -Input @(0,1)) + $BXORSyntax + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '}'

    # Generate the code that will decrypt and execute the payload and randomly select one.
    $BaseScriptArray  = @()
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "[$CharStr[]]" + ' '*(Get-Random -Input @(0,1)) + $EncodedArray + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + $BXORConversion + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'." + $Split + "(" + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimitersToPrint + "'" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + $BXORConversion + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'" + ' '*(Get-Random -Input @(0,1)) + $RandomDelimitersToPrintForDashSplit + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + $BXORConversion + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + $BXORConversion + ' '*(Get-Random -Input @(0,1)) + ')'

    # Generate random JOIN syntax for all above options.
    $NewScriptArray   = @()
    $NewScriptArray  += (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + $Join + ' '*(Get-Random -Input @(0,1)) + "''"
    $NewScriptArray  += $Join + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray)
    $NewScriptArray  += $StrJoin + '(' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + ')'
    $NewScriptArray  += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' + ' '*(Get-Random -Input @(0,1)) + $StrStr + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'

    # Randomly select one of the above commands.
    $NewScript = (Get-Random -Input $NewScriptArray)

    # Generate random invoke operation syntax.
    # Below code block is a copy from Out-ObfuscatedStringCommand.ps1. It is copied into this encoding function so that this will remain a standalone script without dependencies.
    $InvokeExpressionSyntax  = @()
    $InvokeExpressionSyntax += (Get-Random -Input @('IEX','Invoke-Expression'))
    # Added below slightly-randomized obfuscated ways to form the string 'iex' and then invoke it with . or &.
    # Though far from fully built out, these are included to highlight how IEX/Invoke-Expression is a great indicator but not a silver bullet.
    # These methods draw on common environment variable values and PowerShell Automatic Variable values/methods/members/properties/etc.
    $InvocationOperator = (Get-Random -Input @('.','&')) + ' '*(Get-Random -Input @(0,1))
    $InvokeExpressionSyntax += $InvocationOperator + "( `$ShellId[1]+`$ShellId[13]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$PSHome[" + (Get-Random -Input @(4,21)) + "]+`$PSHome[" + (Get-Random -Input @(30,34)) + "]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$env:ComSpec[4," + (Get-Random -Input @(15,24,26)) + ",25]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "((" + (Get-Random -Input @('Get-Variable','GV','Variable')) + " '*mdr*').Name[3,11,2]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "( " + (Get-Random -Input @('$VerbosePreference.ToString()','([String]$VerbosePreference)')) + "[1,3]+'x'-Join'')"
    # Commenting below option since $env:Public differs in string value for non-English operating systems.
    #$InvokeExpressionSyntax += $InvocationOperator + "( `$env:Public[13]+`$env:Public[5]+'x')"

    # Randomly choose from above invoke operation syntaxes.
    $InvokeExpression = (Get-Random -Input $InvokeExpressionSyntax)

    # Randomize the case of selected invoke operation.
    $InvokeExpression = ([Char[]]$InvokeExpression | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    # Choose random Invoke-Expression/IEX syntax and ordering: IEX ($ScriptString) or ($ScriptString | IEX)
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $InvokeExpression + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $InvokeExpression

    $NewScript = (Get-Random -Input $InvokeOptions)

    # If user did not include -PassThru flag then continue with adding execution flgs and powershell.exe to $NewScript.
    If(!$PSBoundParameters['PassThru'])
    {
        # Array to store all selected PowerShell execution flags.
        $PowerShellFlags = @()

        # Build the PowerShell execution flags by randomly selecting execution flags substrings and randomizing the order.
        # This is to prevent Blue Team from placing false hope in simple signatures for common substrings of these execution flags.
        $CommandlineOptions = New-Object String[](0)
        If($PSBoundParameters['NoExit'])
        {
          $FullArgument = "-NoExit";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoProfile'])
        {
          $FullArgument = "-NoProfile";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NonInteractive'])
        {
          $FullArgument = "-NonInteractive";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 5 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoLogo'])
        {
          $FullArgument = "-NoLogo";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['WindowStyle'] -OR $WindowsStyle)
        {
            $FullArgument = "-WindowStyle"
            If($WindowsStyle) {$ArgumentValue = $WindowsStyle}
            Else {$ArgumentValue = $PSBoundParameters['WindowStyle']}

            # Randomly decide to write WindowStyle value with flag substring or integer value.
            Switch($ArgumentValue.ToLower())
            {
                'normal'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('0','n','no','nor','norm','norma'))}}
                'hidden'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('1','h','hi','hid','hidd','hidde'))}}
                'minimized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('2','mi','min','mini','minim','minimi','minimiz','minimize'))}}
                'maximized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('3','ma','max','maxi','maxim','maximi','maximiz','maximize'))}}
                default {Write-Error "An invalid `$ArgumentValue value ($ArgumentValue) was passed to switch block for Out-PowerShellLauncher."; Exit;}
            }

            $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1))) + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }
        If($PSBoundParameters['ExecutionPolicy'] -OR $ExecutionPolicy)
        {
            $FullArgument = "-ExecutionPolicy"
            If($ExecutionPolicy) {$ArgumentValue = $ExecutionPolicy}
            Else {$ArgumentValue = $PSBoundParameters['ExecutionPolicy']}
            # Take into account the shorted flag of -EP as well.
            $ExecutionPolicyFlags = @()
            $ExecutionPolicyFlags += '-EP'
            For($Index=3; $Index -le $FullArgument.Length; $Index++)
            {
                $ExecutionPolicyFlags += $FullArgument.SubString(0,$Index)
            }
            $ExecutionPolicyFlag = Get-Random -Input $ExecutionPolicyFlags
            $PowerShellFlags += $ExecutionPolicyFlag + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }

        # Randomize the order of the execution flags.
        # This is to prevent the Blue Team from placing false hope in simple signatures for ordering of these flags.
        If($CommandlineOptions.Count -gt 1)
        {
            $CommandlineOptions = Get-Random -InputObject $CommandlineOptions -Count $CommandlineOptions.Count
        }

        # If selected then the -Command flag needs to be added last.
        If($PSBoundParameters['Command'])
        {
            $FullArgument = "-Command"
            $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1)))
        }

        # Randomize the case of all command-line arguments.
        For($i=0; $i -lt $PowerShellFlags.Count; $i++)
        {
            $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
        }

        # Random-sized whitespace between all execution flags and encapsulating final string of execution flags.
        $CommandlineOptions = ($CommandlineOptions | ForEach-Object {$_ + " "*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
        $CommandlineOptions = " "*(Get-Random -Minimum 0 -Maximum 3) + $CommandlineOptions + " "*(Get-Random -Minimum 0 -Maximum 3)

        # Build up the full command-line string.
        If($PSBoundParameters['Wow64'])
        {
            $CommandLineOutput = "C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe $($CommandlineOptions) `"$NewScript`""
        }
        Else
        {
            # Obfuscation isn't about saving space, and there are reasons you'd potentially want to fully path powershell.exe (more info on this soon).
            #$CommandLineOutput = "$($Env:windir)\System32\WindowsPowerShell\v1.0\powershell.exe $($CommandlineOptions) `"$NewScript`""
            $CommandLineOutput = "powershell $($CommandlineOptions) `"$NewScript`""
        }

        # Make sure final command doesn't exceed cmd.exe's character limit.
        $CmdMaxLength = 8190
        If($CommandLineOutput.Length -gt $CmdMaxLength)
        {
                Write-Warning "This command exceeds the cmd.exe maximum allowed length of $CmdMaxLength characters! Its length is $($CmdLineOutput.Length) characters."
        }

        $NewScript = $CommandLineOutput
    }

    Return $NewScript
}
