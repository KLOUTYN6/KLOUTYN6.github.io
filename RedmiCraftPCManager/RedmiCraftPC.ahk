#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir A_ScriptDir
FileEncoding "UTF-8"

AppName := "RedmiCraft PC"
MinecraftVersion := "26.3"

global ConfigDir := A_AppData "\RedmiCraftPC"
global ConfigFile := ConfigDir "\settings.ini"
global ServerDir := ""
global JavaPath := ""
global ServerProc := 0
global MainGui := 0
global ConsoleEdit := 0
global CommandEdit := 0
global StatusText := 0
global AddressText := 0
global RamText := 0
global PlayerText := 0
global TailscaleText := 0
global SettingsGui := 0

DirCreate ConfigDir
ServerDir := IniRead(ConfigFile, "General", "ServerDir", A_ScriptDir "\MinecraftServer")
JavaPath := IniRead(ConfigFile, "Java", "Path", "")

BuildMainGui()
RefreshMain()
SetTimer RefreshMain, 1000
SetTimer ReadServerOutput, 250
return

BuildMainGui() {
    global MainGui, StatusText, AddressText, RamText, PlayerText, TailscaleText, ConsoleEdit, CommandEdit

    MainGui := Gui("+Resize +MinSize900x650", AppName " - Minecraft Java " MinecraftVersion)
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.BackColor := "20232A"

    MainGui.SetFont("s18 Bold")
    MainGui.AddText("x24 y18 w500 cFFFFFF", "REDMICRAFT PC")
    MainGui.SetFont("s10")
    MainGui.AddText("x24 y52 w700 cB8C0CC", "Minecraft Java " MinecraftVersion " | Windows PC server manager")

    StatusText := MainGui.AddText("x24 y88 w250 h30 cFF6B6B", "OFFLINE")
    RamText := MainGui.AddText("x300 y88 w200 h30 cFFFFFF", "RAM: 4 GB")
    PlayerText := MainGui.AddText("x520 y88 w260 h30 cFFFFFF", "Players: --")

    MainGui.SetFont("s10 Bold")
    b1 := MainGui.AddButton("x24 y132 w130 h40", "START")
    b2 := MainGui.AddButton("x164 y132 w130 h40", "STOP")
    b3 := MainGui.AddButton("x304 y132 w130 h40", "RESTART")
    b4 := MainGui.AddButton("x444 y132 w130 h40", "SETUP")
    b5 := MainGui.AddButton("x584 y132 w130 h40", "SETTINGS")
    b6 := MainGui.AddButton("x724 y132 w130 h40", "BACKUP")
    b1.OnEvent("Click", StartServer)
    b2.OnEvent("Click", StopServer)
    b3.OnEvent("Click", RestartServer)
    b4.OnEvent("Click", SetupServer)
    b5.OnEvent("Click", OpenSettings)
    b6.OnEvent("Click", BackupWorld)

    MainGui.SetFont("s9")
    MainGui.AddText("x24 y190 w120 cB8C0CC", "Server folder")
    MainGui.AddText("x24 y213 w830 h28 cFFFFFF", ServerDir)

    MainGui.AddText("x24 y252 w150 cB8C0CC", "LAN address")
    AddressText := MainGui.AddText("x180 y252 w280 cFFFFFF", "detecting...")
    MainGui.AddText("x470 y252 w130 cB8C0CC", "Remote play")
    TailscaleText := MainGui.AddText("x600 y252 w300 cFFFFFF", "Checking Tailscale...")

    bt1 := MainGui.AddButton("x24 y292 w180 h36", "OPEN SERVER FOLDER")
    bt2 := MainGui.AddButton("x214 y292 w180 h36", "NETWORK HELP")
    bt3 := MainGui.AddButton("x404 y292 w180 h36", "ALLOW FIREWALL")
    bt4 := MainGui.AddButton("x594 y292 w180 h36", "OPEN TAILSCALE")
    bt1.OnEvent("Click", OpenServerFolder)
    bt2.OnEvent("Click", OpenNetworkHelp)
    bt3.OnEvent("Click", AllowFirewall)
    bt4.OnEvent("Click", OpenTailscale)

    MainGui.SetFont("s10 Bold")
    MainGui.AddText("x24 y350 w220 cFFFFFF", "SERVER CONSOLE")
    MainGui.SetFont("s9")
    ConsoleEdit := MainGui.AddEdit("x24 y380 w830 h220 -Wrap +HScroll +VScroll ReadOnly cE8E8E8 Background202020", "RedmiCraft PC ready." Chr(10))
    CommandEdit := MainGui.AddEdit("x24 y610 w700 h32", "")
    send := MainGui.AddButton("x734 y610 w120 h32", "SEND")
    send.OnEvent("Click", SendConsoleCommand)
    MainGui.AddText("x24 y646 w830 c8B94A7", "Remote play: Tailscale works across different Wi-Fi networks.")

    MainGui.OnEvent("Close", CloseProgram)
    MainGui.OnEvent("Size", ResizeMain)
    MainGui.Show("w900 h690")
}

ResizeMain(guiObj, minMax, width, height) {
    global ConsoleEdit, CommandEdit
    if minMax = -1
        return
    ConsoleEdit.Move(24, 380, width - 48, height - 470)
    CommandEdit.Move(24, height - 80, width - 200, 32)
}

RefreshMain(*) {
    global StatusText, AddressText, RamText, PlayerText, TailscaleText, TailscaleText
    if IsServerRunning() {
        StatusText.Text := "ONLINE"
        StatusText.SetFont("c7CFF6B Bold")
    } else {
        StatusText.Text := "OFFLINE"
        StatusText.SetFont("cFF6B6B Bold")
    }
    xmx := IniRead(ConfigFile, "Performance", "Xmx", "4")
    RamText.Text := "RAM: " xmx " GB"
    port := IniRead(ConfigFile, "Network", "Port", "25565")
    AddressText.Text := GetLanIP() ":" port
    ts := GetTailscaleIP()
    TailscaleText.Text := ts != "" ? "READY: " ts ":" port : "Not connected"
    PlayerText.Text := "Players: " ParsePlayerCount()
}

OpenSettings(*) {
    global SettingsGui, MainGui, ServerDir, JavaPath
    if IsObject(SettingsGui) {
        try {
            SettingsGui.Show()
            return
        }
    }

    SettingsGui := Gui("+Owner" MainGui.Hwnd, "RedmiCraft PC Settings")
    SettingsGui.SetFont("s10", "Segoe UI")

    SettingsGui.AddText("x20 y16 w300", "PC / JAVA")
    SettingsGui.AddText("x20 y50 w120", "Server folder")
    eFolder := SettingsGui.AddEdit("x150 y46 w450", ServerDir)
    bFolder := SettingsGui.AddButton("x610 y46 w90", "Browse")
    bFolder.OnEvent("Click", (*) => ChooseFolder(eFolder))

    SettingsGui.AddText("x20 y90 w120", "Java 25 path")
    eJava := SettingsGui.AddEdit("x150 y86 w450", JavaPath)
    bJava := SettingsGui.AddButton("x610 y86 w90", "Browse")
    bJava.OnEvent("Click", (*) => ChooseJava(eJava))

    SettingsGui.AddText("x20 y130 w120", "Xms (GB)")
    cbXms := SettingsGui.AddComboBox("x150 y126 w120", ["1","2","3","4","5","6","8"])
    cbXms.Text := IniRead(ConfigFile, "Performance", "Xms", "4")
    SettingsGui.AddText("x300 y130 w120", "Xmx (GB)")
    cbXmx := SettingsGui.AddComboBox("x430 y126 w120", ["2","3","4","5","6","8","10","12"])
    cbXmx.Text := IniRead(ConfigFile, "Performance", "Xmx", "4")

    SettingsGui.AddText("x20 y170 w120", "GC mode")
    cbGC := SettingsGui.AddComboBox("x150 y166 w260", ["Default G1","ZGC (Java 25)"])
    cbGC.Text := IniRead(ConfigFile, "Performance", "GC", "Default G1")
    SettingsGui.AddText("x450 y170 w250 c666666", "ZGC is optional for Java 25.")

    SettingsGui.AddText("x20 y210 w120", "Port")
    ePort := SettingsGui.AddEdit("x150 y206 w120", IniRead(ConfigFile, "Network", "Port", "25565"))
    SettingsGui.AddText("x300 y210 w120", "Max players")
    eMaxPlayers := SettingsGui.AddEdit("x430 y206 w120", IniRead(ConfigFile, "Server", "MaxPlayers", "4"))

    SettingsGui.AddText("x20 y250 w120", "Difficulty")
    cbDiff := SettingsGui.AddComboBox("x150 y246 w150", ["peaceful","easy","normal","hard"])
    cbDiff.Text := IniRead(ConfigFile, "World", "Difficulty", "normal")
    SettingsGui.AddText("x330 y250 w90", "Gamemode")
    cbMode := SettingsGui.AddComboBox("x430 y246 w150", ["survival","creative","adventure","spectator"])
    cbMode.Text := IniRead(ConfigFile, "World", "Gamemode", "survival")

    SettingsGui.AddText("x20 y290 w120", "View distance")
    eView := SettingsGui.AddEdit("x150 y286 w120", IniRead(ConfigFile, "Server", "ViewDistance", "8"))
    SettingsGui.AddText("x300 y290 w120", "Simulation")
    eSim := SettingsGui.AddEdit("x430 y286 w120", IniRead(ConfigFile, "Server", "SimulationDistance", "6"))

    cPvp := SettingsGui.AddCheckbox("x20 y330 w170", "Enable PvP")
    cPvp.Value := IniRead(ConfigFile, "Server", "Pvp", "1")
    cCmd := SettingsGui.AddCheckbox("x210 y330 w200", "Command blocks")
    cCmd.Value := IniRead(ConfigFile, "Server", "CommandBlocks", "0")
    cCheats := SettingsGui.AddCheckbox("x430 y330 w190", "Allow commands")
    cCheats.Value := IniRead(ConfigFile, "Server", "AllowCommands", "0")
    cWhitelist := SettingsGui.AddCheckbox("x20 y365 w170", "Whitelist only")
    cWhitelist.Value := IniRead(ConfigFile, "Server", "Whitelist", "1")
    cOffline := SettingsGui.AddCheckbox("x210 y365 w220 cCC5555", "Offline authentication")
    cOffline.Value := IniRead(ConfigFile, "Server", "OfflineAuth", "0")
    cAuto := SettingsGui.AddCheckbox("x450 y365 w220", "Auto-start with app")
    cAuto.Value := IniRead(ConfigFile, "General", "AutoStart", "0")

    SettingsGui.AddText("x20 y405 w680 h50 c666666", "Offline authentication disables Mojang account verification for this server. Use only on a trusted private network because usernames can be impersonated.")

    save := SettingsGui.AddButton("x420 y475 w140 h38", "SAVE")
    cancel := SettingsGui.AddButton("x570 y475 w140 h38", "CLOSE")
    save.OnEvent("Click", (*) => SaveSettings(eFolder, eJava, cbXms, cbXmx, cbGC, ePort, eMaxPlayers, cbDiff, cbMode, eView, eSim, cPvp, cCmd, cCheats, cWhitelist, cOffline, cAuto))
    cancel.OnEvent("Click", (*) => SettingsGui.Hide())
    SettingsGui.OnEvent("Close", (*) => SettingsGui.Hide())
    SettingsGui.Show("w730 h540")
}

ChooseFolder(ctrl) {
    picked := DirSelect(ctrl.Value, 0, "Choose Minecraft server folder")
    if picked != ""
        ctrl.Value := picked
}

ChooseJava(ctrl) {
    picked := FileSelect(1, , "Choose Java 25 java.exe", "Programs (*.exe)")
    if picked != ""
        ctrl.Value := picked
}

SaveSettings(eFolder, eJava, cbXms, cbXmx, cbGC, ePort, eMaxPlayers, cbDiff, cbMode, eView, eSim, cPvp, cCmd, cCheats, cWhitelist, cOffline, cAuto) {
    global ServerDir, JavaPath, SettingsGui
    if !IsInteger(ePort.Value) || Integer(ePort.Value) < 1 || Integer(ePort.Value) > 65535 {
        MsgBox "Port must be between 1 and 65535.", "RedmiCraft PC", 48
        return
    }
    if Integer(cbXms.Text) > Integer(cbXmx.Text) {
        MsgBox "Xms cannot be larger than Xmx.", "RedmiCraft PC", 48
        return
    }

    ServerDir := eFolder.Value
    JavaPath := eJava.Value
    DirCreate ConfigDir

    IniWrite ServerDir, ConfigFile, "General", "ServerDir"
    IniWrite JavaPath, ConfigFile, "Java", "Path"
    IniWrite cbXms.Text, ConfigFile, "Performance", "Xms"
    IniWrite cbXmx.Text, ConfigFile, "Performance", "Xmx"
    IniWrite cbGC.Text, ConfigFile, "Performance", "GC"
    IniWrite ePort.Value, ConfigFile, "Network", "Port"
    IniWrite eMaxPlayers.Value, ConfigFile, "Server", "MaxPlayers"
    IniWrite cbDiff.Text, ConfigFile, "World", "Difficulty"
    IniWrite cbMode.Text, ConfigFile, "World", "Gamemode"
    IniWrite eView.Value, ConfigFile, "Server", "ViewDistance"
    IniWrite eSim.Value, ConfigFile, "Server", "SimulationDistance"
    IniWrite cPvp.Value, ConfigFile, "Server", "Pvp"
    IniWrite cCmd.Value, ConfigFile, "Server", "CommandBlocks"
    IniWrite cCheats.Value, ConfigFile, "Server", "AllowCommands"
    IniWrite cWhitelist.Value, ConfigFile, "Server", "Whitelist"
    IniWrite cOffline.Value, ConfigFile, "Server", "OfflineAuth"
    IniWrite cAuto.Value, ConfigFile, "General", "AutoStart"

    ApplyServerProperties()
    AppendLog("Settings saved.")
    SettingsGui.Hide()
}

SetupServer(*) {
    global ServerDir
    if IsServerRunning() {
        MsgBox "Stop the server before setup.", "RedmiCraft PC", 48
        return
    }

    answer := MsgBox("Minecraft 26.3 requires Java 25 or newer." Chr(10) Chr(10) "The manager will create the server folder and download the official 26.3 server JAR from Mojang." Chr(10) Chr(10) "Have you accepted the Minecraft EULA for this server?", "RedmiCraft PC Setup", "YN Icon?")
    if answer != "Yes"
        return

    if !FindJava(true)
        return

    DirCreate ServerDir
    DirCreate ServerDir "\backups"
    AppendLog("Getting official Minecraft 26.3 server download URL...")

    url := GetMinecraftServerUrl()
    if url = "" {
        MsgBox "Could not retrieve the official 26.3 server URL.", "RedmiCraft PC", 16
        return
    }

    try {
        Download url, ServerDir "\server.jar"
    } catch as err {
        MsgBox "Server download failed:" Chr(10) err.Message, "RedmiCraft PC", 16
        return
    }

    FileDelete ServerDir "\eula.txt"
    FileAppend "eula=true" Chr(10), ServerDir "\eula.txt", "UTF-8"
    IniWrite 1, ConfigFile, "General", "EulaAccepted"
    ApplyServerProperties()

    MsgBox "Setup complete!" Chr(10) Chr(10) "Minecraft Java 26.3 is ready." Chr(10) "Java: " JavaPath, "RedmiCraft PC", 64
    AppendLog("Setup complete.")
}

GetMinecraftServerUrl() {
    shell := ComObject("WScript.Shell")
    ps := "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command " Chr(34) "$m=Invoke-RestMethod 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json'; $v=$m.versions | Where-Object {$_.id -eq '26.3'} | Select-Object -First 1; if (!$v) { exit 2 }; $meta=Invoke-RestMethod $v.url; [Console]::Write($meta.downloads.server.url)" Chr(34)
    try {
        e := shell.Exec(ps)
        return Trim(e.StdOut.ReadAll())
    } catch {
        return ""
    }
}

StartServer(*) {
    global ServerProc, ServerDir, JavaPath
    if IsServerRunning() {
        AppendLog("Server is already running.")
        return
    }

    if !FileExist(ServerDir "\server.jar") {
        MsgBox "Server is not installed. Press SETUP first.", "RedmiCraft PC", 48
        return
    }

    if !FindJava(true)
        return

    ApplyServerProperties()

    xms := IniRead(ConfigFile, "Performance", "Xms", "4")
    xmx := IniRead(ConfigFile, "Performance", "Xmx", "4")
    gc := IniRead(ConfigFile, "Performance", "GC", "Default G1")
    gcArgs := gc = "ZGC (Java 25)" ? "-XX:+UseZGC " : ""

    cmd := '"' JavaPath '" -Xms' xms 'G -Xmx' xmx 'G ' gcArgs '-jar "' ServerDir '\server.jar" nogui'

    try {
        shell := ComObject("WScript.Shell")
        shell.CurrentDirectory := ServerDir
        ServerProc := shell.Exec(cmd)
        AppendLog("START_REQUESTED")
    } catch as err {
        ServerProc := 0
        MsgBox "Could not start Java:" Chr(10) err.Message, "RedmiCraft PC", 16
    }
}

StopServer(*) {
    global ServerProc
    if !IsServerRunning() {
        AppendLog("Server is already stopped.")
        return
    }
    try {
        ServerProc.StdIn.WriteLine("stop")
        AppendLog("STOP_REQUESTED")
    } catch {
        try ProcessClose(ServerProc.ProcessID)
    }
    Sleep 1200
    if IsServerRunning() {
        try ProcessClose(ServerProc.ProcessID)
    }
}

RestartServer(*) {
    StopServer()
    Sleep 1500
    StartServer()
}

SendConsoleCommand(*) {
    global ServerProc, CommandEdit
    if !IsServerRunning() {
        AppendLog("Cannot send command: server is offline.")
        return
    }
    cmd := Trim(CommandEdit.Value)
    if cmd = ""
        return
    CommandEdit.Value := ""
    try {
        ServerProc.StdIn.WriteLine(cmd)
        AppendLog("> " cmd)
    } catch {
        AppendLog("Command failed.")
    }
}

ReadServerOutput(*) {
    global ServerProc
    if !IsServerRunning()
        return
    try {
        while !ServerProc.StdOut.AtEndOfStream {
            line := ServerProc.StdOut.ReadLine()
            if line != ""
                AppendLog(line)
        }
    } catch {
    }
}

AppendLog(line) {
    global ConsoleEdit
    if !IsObject(ConsoleEdit)
        return
    stamp := FormatTime(, "HH:mm:ss")
    try ConsoleEdit.Value .= "[" stamp "] " line Chr(10)
}

BackupWorld(*) {
    global ServerDir
    world := ServerDir "\world"
    if !DirExist(world) {
        MsgBox "No world folder exists yet.", "RedmiCraft PC", 48
        return
    }
    if IsServerRunning() {
        answer := MsgBox("For a clean backup, stop the server first." Chr(10) Chr(10) "Stop it now and create the backup?", "RedmiCraft PC", "YN Icon?")
        if answer != "Yes"
            return
        StopServer()
        Sleep 1500
    }

    backupDir := ServerDir "\backups"
    DirCreate backupDir
    target := backupDir "\world-" FormatTime(, "yyyyMMdd-HHmmss") ".zip"
    q := Chr(34)
    command := "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command " q "Compress-Archive -Path " Chr(39) world Chr(39) " -DestinationPath " Chr(39) target Chr(39) " -Force" q
    RunWait command, , "Hide"

    if FileExist(target) {
        AppendLog("Backup created: " target)
        MsgBox "Backup created:" Chr(10) target, "RedmiCraft PC", 64
    } else {
        MsgBox "Backup failed.", "RedmiCraft PC", 16
    }
}

ApplyServerProperties() {
    global ServerDir
    DirCreate ServerDir

    port := IniRead(ConfigFile, "Network", "Port", "25565")
    maxPlayers := IniRead(ConfigFile, "Server", "MaxPlayers", "4")
    diff := IniRead(ConfigFile, "World", "Difficulty", "normal")
    mode := IniRead(ConfigFile, "World", "Gamemode", "survival")
    view := IniRead(ConfigFile, "Server", "ViewDistance", "8")
    sim := IniRead(ConfigFile, "Server", "SimulationDistance", "6")
    pvp := IniRead(ConfigFile, "Server", "Pvp", "1")
    commandBlocks := IniRead(ConfigFile, "Server", "CommandBlocks", "0")
    allowCommands := IniRead(ConfigFile, "Server", "AllowCommands", "0")
    whitelist := IniRead(ConfigFile, "Server", "Whitelist", "1")
    offline := IniRead(ConfigFile, "Server", "OfflineAuth", "0")

    onlineMode := offline = "1" ? "false" : "true"
    cheats := allowCommands = "1" ? "true" : "false"

    props := "motd=Tony & Girlfriend Server" Chr(10)
        . "server-port=" port Chr(10)
        . "max-players=" maxPlayers Chr(10)
        . "difficulty=" diff Chr(10)
        . "gamemode=" mode Chr(10)
        . "view-distance=" view Chr(10)
        . "simulation-distance=" sim Chr(10)
        . "pvp=" pvp Chr(10)
        . "enable-command-block=" commandBlocks Chr(10)
        . "allow-cheats=" cheats Chr(10)
        . "white-list=" whitelist Chr(10)
        . "enforce-whitelist=" whitelist Chr(10)
        . "online-mode=" onlineMode Chr(10)
        . "server-ip=" Chr(10)
        . "spawn-protection=0" Chr(10)
        . "enable-status=true" Chr(10)
        . "broadcast-console-to-ops=true" Chr(10)

    FileDelete ServerDir "\server.properties"
    FileAppend props, ServerDir "\server.properties", "UTF-8"
}

FindJava(showError := false) {
    global JavaPath
    if JavaPath != "" && FileExist(JavaPath) && GetJavaMajor(JavaPath) >= 25
        return true

    try {
        shell := ComObject("WScript.Shell")
        e := shell.Exec("where.exe java")
        out := Trim(e.StdOut.ReadAll())
        if out != "" {
            found := StrSplit(out, Chr(10))[1]
            found := Trim(found)
            if FileExist(found) && GetJavaMajor(found) >= 25 {
                JavaPath := found
                IniWrite JavaPath, ConfigFile, "Java", "Path"
                return true
            }
        }
    } catch {
    }

    if showError
        MsgBox "Java 25 or newer was not found." Chr(10) Chr(10) "Minecraft 26.3 needs Java 25 or newer." Chr(10) Chr(10) "Install Microsoft OpenJDK 25, then reopen RedmiCraft PC.", "RedmiCraft PC", 48
    return false
}

GetJavaMajor(path) {
    try {
        shell := ComObject("WScript.Shell")
        e := shell.Exec('"' path '" -version')
        out := e.StdErr.ReadAll() e.StdOut.ReadAll()
        if RegExMatch(out, 'version "(\d+)', &m)
            return Integer(m[1])
        if RegExMatch(out, 'openjdk (\d+)', &m)
            return Integer(m[1])
    } catch {
    }
    return 0
}

GetLanIP() {
    shell := ComObject("WScript.Shell")
    try {
        ps := "powershell.exe -NoProfile -Command " Chr(34) "(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike '169.254*' -and $_.IPAddress -notlike '127.*'} | Select-Object -First 1 -ExpandProperty IPAddress)" Chr(34)
        e := shell.Exec(ps)
        out := Trim(e.StdOut.ReadAll())
        if RegExMatch(out, "(\d{1,3}(?:\.\d{1,3}){3})", &m)
            return m[1]
    } catch {
    }
    return "0.0.0.0"
}

GetTailscaleIP() {
    try {
        shell := ComObject("WScript.Shell")
        e := shell.Exec("cmd.exe /c tailscale ip -4")
        out := Trim(e.StdOut.ReadAll())
        if RegExMatch(out, "(\d{1,3}(?:\.\d{1,3}){3})", &m)
            return m[1]
    } catch {
    }
    return ""
}

ParsePlayerCount() {
    global ServerDir
    log := ServerDir "\logs\latest.log"
    if !FileExist(log)
        return "--"
    try {
        f := FileOpen(log, "r", "UTF-8")
        size := f.Length
        f.Seek(Max(0, size - 50000))
        data := f.Read()
        f.Close()
        if RegExMatch(data, "There are (\d+) of a max of (\d+) players online", &m)
            return m[1] "/" m[2]
        return "0/" IniRead(ConfigFile, "Server", "MaxPlayers", "4")
    } catch {
        return "--"
    }
}

IsServerRunning() {
    global ServerProc
    try {
        return IsObject(ServerProc) && ServerProc.Status = 0
    } catch {
        return false
    }
}

OpenServerFolder(*) {
    global ServerDir
    DirCreate ServerDir
    Run ServerDir
}

OpenNetworkHelp(*) {
    MsgBox "Different Wi-Fi networks are fine." Chr(10) Chr(10) "Recommended:" Chr(10) "1. Install Tailscale on this PC." Chr(10) "2. Install Tailscale on your girlfriend's PC." Chr(10) "3. Sign both devices into the same Tailscale network." Chr(10) "4. Start the server here." Chr(10) "5. She connects to the Tailscale IP shown in this app plus :25565." Chr(10) Chr(10) "Alternative: port-forward TCP 25565 on your router, then use your public IP.", "RedmiCraft PC Network", 64
}

OpenTailscale(*) {
    Run "https://tailscale.com/download/windows"
}

AllowFirewall(*) {
    rule := 'netsh advfirewall firewall add rule name="RedmiCraft Minecraft 25565" dir=in action=allow protocol=TCP localport=25565'
    try {
        Run('*RunAs "' A_ComSpec '" /c ' rule)
    } catch {
        MsgBox "Windows could not start the firewall helper.", "RedmiCraft PC", 16
    }
}

CloseProgram(*) {
    global ServerProc
    if IsServerRunning() {
        answer := MsgBox("Minecraft is still running." Chr(10) Chr(10) "Stop the server and close RedmiCraft PC?", "RedmiCraft PC", "YNC Icon?")
        if answer = "Cancel"
            return
        if answer = "Yes" {
            try {
                ServerProc.StdIn.WriteLine("stop")
            }
            Sleep 1200
            try {
                if IsServerRunning()
                    ProcessClose(ServerProc.ProcessID)
            }
        }
    }
    ExitApp()
}
