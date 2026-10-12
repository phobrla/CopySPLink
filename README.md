# Copy SharePoint Link

Adds **Copy SharePoint Link** to the Windows File Explorer context menu. It copies a persistent SharePoint link for a file in a OneDrive-synced SharePoint library.

The link type is selected from the file extension: Excel (`:x:`), Word (`:w:`), PowerPoint (`:p:`), OneNote (`:o:`), PDF (`:b:`), or the generic viewer (`:u:`). PDF links are path-based and omit the `e=` share token.

## Requirements

- Windows with the target SharePoint library synced through OneDrive.
- Python available as either `python` or the Windows Python launcher `py`.
- Inno Setup 6 to build the installer.

## Build and install

From this directory, run:

```powershell
ISCC.exe .\CopySPLink.iss
```

The installer is written to `dist\CopySPLink-Setup.exe`. Run it to install for the current user; administrator rights are not required. The installer registers the Explorer context-menu command under `HKCU` and includes both scripts.

## Use

Right-click a synced file in File Explorer and select **Copy SharePoint Link**, then paste the link where needed. Newly synced files may take a short time to appear in OneDrive's local database.

## Manual registration

To register without building the installer, create the `HKCU\Software\Classes\*\shell\CopySPLink\command` default value as:

```text
"powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "<full path>\Get-SharePointLink.ps1" "%1"
```

Remove the `HKCU\Software\Classes\*\shell\CopySPLink` key to uninstall the manual registration.
