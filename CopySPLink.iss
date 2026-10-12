; Inno Setup script. Build with: ISCC.exe CopySPLink.iss
[Setup]
AppName=Copy SharePoint Link
AppVersion=1.0
AppPublisher=JHP
DefaultDirName={localappdata}\Programs\CopySPLink
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
DisableDirPage=yes
OutputBaseFilename=CopySPLink-Setup
OutputDir=dist
Compression=lzma
SolidCompression=yes
UninstallDisplayName=Copy SharePoint Link
; Optional signing: configure a SignTool in Inno, then uncomment.
; SignTool=mysigntool

[Files]
Source: "Get-SharePointLink.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Get-SharePointLink.py"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Classes\*\shell\CopySPLink"; ValueType: string; ValueData: "Copy SharePoint Link"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\*\shell\CopySPLink\command"; ValueType: string; ValueData: """powershell.exe"" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\Get-SharePointLink.ps1"" ""%1"""; Flags: uninsdeletekey

[Code]
function InitializeSetup(): Boolean;
var
  Rc: Integer;
begin
  Result := True;
  if (not Exec('python', '--version', '', SW_HIDE, ewWaitUntilTerminated, Rc)) or (Rc <> 0) then
    if (not Exec('py', '--version', '', SW_HIDE, ewWaitUntilTerminated, Rc)) or (Rc <> 0) then
      Result := MsgBox('Python was not found on PATH. The menu item needs it to work. Install anyway?', mbConfirmation, MB_YESNO) = IDYES;
end;
