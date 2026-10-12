param([Parameter(Mandatory)][string]$Path)

# Explorer context menu "Copy SharePoint Link": puts a persistent SharePoint link for a
# OneDrive-synced file on the clipboard (no need for "View online" + SharePoint Links add-in).

$ErrorActionPreference = 'Stop'

function Show-Error([string]$Message) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show($Message, 'Copy SharePoint Link')
    exit 1
}

try {
    $file = (Resolve-Path -LiteralPath $Path).ProviderPath
    $item = Get-Item -LiteralPath $file -Force
    if ($item.PSIsContainer) { Show-Error 'Folders are not supported.' }

    # Find the sync root containing this file (longest mount point wins).
    $roots = Get-ChildItem 'HKCU:\Software\SyncEngines\Providers\OneDrive' |
        ForEach-Object { Get-ItemProperty $_.PSPath } |
        Where-Object { $_.MountPoint -and $_.UrlNamespace -and $_.WebUrl } |
        Sort-Object { $_.MountPoint.Length } -Descending
    $root = $roots | Where-Object { $file.StartsWith($_.MountPoint.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
    if (-not $root) { Show-Error 'File is not inside a synced SharePoint/OneDrive library.' }

    $uri = [Uri]$root.WebUrl
    $webPath = $uri.AbsolutePath.TrimEnd('/')          # e.g. /sites/EpicJHP
    $siteHost = $uri.GetLeftPart([UriPartial]::Authority)

    # NTFS file id (low 64 bits) is what OneDrive stores as itemIndex.
    $idLine = (fsutil file queryfileid $file) -join ' '
    if ($idLine -notmatch '0x([0-9a-fA-F]+)') { Show-Error 'Could not read file id.' }
    $hex = $Matches[1]; if ($hex.Length -gt 16) { $hex = $hex.Substring($hex.Length - 16) }
    $itemIndex = [Convert]::ToUInt64($hex, 16)

    $py = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $py) { $py = (Get-Command py -ErrorAction SilentlyContinue).Source }
    if (-not $py) { Show-Error 'Python was not found on PATH.' }
    $guid = (& $py (Join-Path $PSScriptRoot 'Get-SharePointLink.py') $itemIndex $item.Name | Select-Object -First 1)
    if (-not $guid) { Show-Error "OneDrive has no record of '$($item.Name)' yet. Wait for sync to finish and retry." }

    $ext = $item.Extension.TrimStart('.').ToLowerInvariant()
    $type = switch -Regex ($ext) {
        '^pdf$'                          { 'b' }
        '^(xls|xlsx|xlsm|xlsb|csv)$'     { 'x' }
        '^(doc|docx|docm)$'              { 'w' }
        '^(ppt|pptx|pptm)$'              { 'p' }
        '^one$'                          { 'o' }
        default                          { 'u' }   # vsdx and everything else
    }

    if ($type -eq 'b') {
        # PDFs have no Doc.aspx viewer; use a path-based link with the d= unique id.
        $rel = $file.Substring($root.MountPoint.TrimEnd('\').Length).TrimStart('\') -split '\\'
        $libPath = ([Uri]$root.UrlNamespace).AbsolutePath.TrimEnd('/')
        $enc = ($rel | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
        $link = "$siteHost/:b:/r$libPath/$enc" + '?d=w' + $guid.Replace('-', '').ToLowerInvariant() + '&csf=1&web=1'
    } else {
        $link = "$siteHost/:$type`:/r$webPath/_layouts/15/Doc.aspx?sourcedoc={$guid}"
    }

    Set-Clipboard -Value $link
}
catch {
    Show-Error $_.Exception.Message
}
