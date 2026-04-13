param([string]$SessionName = "unknown")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Custom form that never steals focus from the active window
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @"
using System.Windows.Forms;
public class NoActivateForm : Form {
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get {
            const int WS_EX_NOACTIVATE = 0x08000000;
            const int WS_EX_TOPMOST = 0x00000008;
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_NOACTIVATE | WS_EX_TOPMOST;
            return cp;
        }
    }
}
"@

$pidDir = "C:\Temp"
$pidFile = "$pidDir\claude-notify-$SessionName.pid"

# Count existing notification windows to determine vertical position
$existingPids = Get-ChildItem "$pidDir\claude-notify-*.pid" -ErrorAction SilentlyContinue
$slot = 0
foreach ($f in $existingPids) {
    $p = Get-Content $f -ErrorAction SilentlyContinue
    if ($p -and (Get-Process -Id $p -ErrorAction SilentlyContinue)) {
        $slot++
    } else {
        Remove-Item $f -Force -ErrorAction SilentlyContinue
    }
}

$form = New-Object NoActivateForm
$form.Text = "Claude Code"
$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$shadow = 4
$contentHeight = 50
$windowHeight = $contentHeight + $shadow
$gap = 5
$form.Size = New-Object System.Drawing.Size((340 + $shadow), $windowHeight)
$form.Location = New-Object System.Drawing.Point(($screen.Right - 350 - $shadow), ($screen.Top + 10 + ($slot * ($windowHeight + $gap))))
$form.BackColor = [System.Drawing.Color]::Magenta
$form.TransparencyKey = [System.Drawing.Color]::Magenta

# Content panel
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(340, $contentHeight)
$panel.Location = New-Object System.Drawing.Point(0, 0)
$panel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$form.Controls.Add($panel)

$label = New-Object System.Windows.Forms.Label
$label.Text = "Claude:  $SessionName"
$label.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$label.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$label.AutoSize = $false
$label.Dock = 'Fill'
$label.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0)
$label.TextAlign = 'MiddleLeft'
$panel.Controls.Add($label)

# Click anywhere to close
$closeHandler = { $form.Close() }
$panel.Add_Click($closeHandler)
$label.Add_Click($closeHandler)

# Draw border and shadow
$form.Add_Paint({
    $g = $_.Graphics
    # Soft shadow - solid gray layers, lightest to darkest
    $colors = @(235, 225, 215, 205)
    for ($i = $shadow; $i -ge 1; $i--) {
        $c = $colors[$i - 1]
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($c, $c, $c))
        $g.FillRectangle($brush, $i, $i, 340, $contentHeight)
        $brush.Dispose()
    }
    # Content background (redraw on top of shadow)
    $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 245, 245))
    $g.FillRectangle($bg, 0, 0, 340, $contentHeight)
    $bg.Dispose()
    # Border
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 210, 210), 1)
    $g.DrawRectangle($pen, 0, 0, 339, ($contentHeight - 1))
    $pen.Dispose()
})

# Timer to restack windows every 500ms
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    $files = Get-ChildItem "$pidDir\claude-notify-*.pid" -ErrorAction SilentlyContinue | Sort-Object Name
    $mySlot = 0
    foreach ($f in $files) {
        if ($f.FullName -eq $pidFile) { break }
        $p = Get-Content $f -ErrorAction SilentlyContinue
        if ($p -and (Get-Process -Id $p -ErrorAction SilentlyContinue)) {
            $mySlot++
        } else {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
        }
    }
    $targetY = $screen.Top + 10 + ($mySlot * ($windowHeight + $gap))
    if ($form.Location.Y -ne $targetY) {
        $form.Location = New-Object System.Drawing.Point(($screen.Right - 350), $targetY)
    }
})

$form.Add_Shown({
    $PSItem | Out-Null
    [System.IO.File]::WriteAllText($pidFile, "$PID")
    $timer.Start()
})
$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
})

[System.Windows.Forms.Application]::Run($form)
