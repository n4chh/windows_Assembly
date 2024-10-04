enum logLevel {
    Debug = 0
    Running = 1
    Info = 2
    Warning = 3
    Success = 4
    Error = 5
}
function Log-String {
  param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string]$String,
    [logLevel]$Level = [logLevel]::Info,
    [logLevel]$BaseLevel = [logLevel]::Info,
    [System.Management.Automation.SwitchParameter]$Date
  )
  if ($Level -lt $BaseLevel) {
    return
  }

  switch ( $level ) {
    Debug {
      Write-Host -ForeGround Cyan -NoNewLine '[#]'
    }
    Info {
      Write-Host -ForeGround DarkCyan  -NoNewLine '[*]'
    }
    Success {
      Write-Host -ForeGround Green  -NoNewLine '[+]'
    }
    Running {
      Write-Host -ForeGround Yellow -NoNewLine '[$]'
    }
    Warning {
      Write-Host -ForeGround DarkYellow -NoNewLine '[-]'
    }
    Error {
      Write-Host -ForeGround Red  -NoNewLine '[!]'
    }
  }

  if ( $Date.ToBool() )
  {
    Write-Host ' ' -NoNewLine
    Write-Host "[$(Get-Date -Format 'MM/dd/yy HH:mm:ss')]" -NoNewLine
  }
  Write-Host ': ' -NoNewLine
  Write-Host $String
}

Set-Alias log Log-String

function Load-DevShell {
  Import-Module "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
  Enter-VsDevShell 66295915  -DevCmdArguments "-arch=x64 -host_arch=x64"
}

function Build-Assembly {
  param (
    # Path to asm file
    [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
    [string[]]
    $Path,
    # Output Date when building
    [logLevel]
    $Level = [logLevel]::Info,
    [System.Management.Automation.SwitchParameter]
    $Date,
    # Assembler Flags
    [string[]]
    $AssemblerFlags,
    # Linker Flags
    [string[]]
    $LinkerFlags
    # Build Extension
    # [Parameter()]
    # [ParameterType]
    # $ParameterName
  )

  if (! $(test-path Env:DevEnvDir)) {
    log "Developer Shell not loaded" -Level Warning -Date:$Date -BaseLevel:$Level
    log "Loading Developer Shell" -Date:$Date -BaseLevel:$Level
    Load-DevShell
    log "Loaded Developer Shell" -Date:$Date -Level Success -BaseLevel:$Level
  }


  $baseName = (Get-Item $Path).BaseName
  $buildDir = "${baseName} Build"
  $obj = "$baseName.obj"
  $exe = "$baseName.exe"
  
  $dir = Get-ChildItem $buildDir -ErrorAction Ignore
  if ($? -eq $false){
    log "Creating builDirectory" -Date:$Date -BaseLevel:$Level
    $createDir = "New-Item  -Type Directory `"$buildDir`""
    log $createDir -Level Running -Date:$Date -BaseLevel:$Level
    Invoke-Expression $createDir | Out-Null
    if ($? -eq $false) {
      log "There was an error creating $buildDir." -Level Error  -Date:$Date -BaseLevel:$Level
      return
    }
  }
  elseif ($dir.Count -gt 0) {
    log "$buildDir is not empty." -Level Warning
    $opt = Read-Host "Would you like to clean it before? Y/n"
    if ($opt -ne 'n') {
      log "Removing following items: '$($dir.Name -Join "' '")'" -Level Info -Date:$Date -BaseLevel:$Level
      foreach ($d in $dir) {
        Remove-Item $d.Name 
      }
    }
  }
  log "Assembling $Path" -Date:$Date -BaseLevel:$Level
  $asmCmd = "nasm -f win64 $Path -o `"$buildDir/$obj`" -l `"$buildDir/$baseName.lst`"$($AssemblerFlags -join ' ')" 
  log "$asmCmd" -Level Running -Date:$Date -BaseLevel:$Level
  Invoke-Expression $asmCmd
  if ($? -eq $false){
    log "There was an error when assembling $Path" -Level Error -Date:$Date -BaseLevel:$Level
    return
  }
  log "File $Path was Assembled" -Level Success -Date:$Date -BaseLevel:$Level

  log "Linking $obj" -Date:$Date -BaseLevel:$Level
  $linkCmd = "link `"$buildDir/$obj`" /subsystem:console /entry:main /out:`"$buildDir/$exe`" $($LinkerFlags -join ' ') kernel32.lib legacy_stdio_definitions.lib msvcrt.lib"
  log "$linkCmd" -Level Running -Date:$Date -BaseLevel:$Level
  Invoke-Expression $linkCmd
  if ($? -eq $false){
    log "There was an error when linking $obj" -Level Error -Date:$Date -BaseLevel:$Level
    return
  }
  log "File $Path was Assembled" -Level Success -Date:$Date -BaseLevel:$Level
}


