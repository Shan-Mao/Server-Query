#Requires AutoHotkey v2.0
#SingleInstance Off
; ================================================================
; Minecraft 服务器状态查询 - AHK v2
; 无边框深色窗口，WinHttpRequest 直连 API
; 首次使用修改下方 DefaultServer
; ================================================================

DefaultServer := "mc.hypixel.net"
DefaultApiKey := ""
ConfigFile    := A_ScriptDir "\server-config.ini"

; ========== 颜色常量 ==========
CLR_BG    := "0d1117"
CLR_CARD  := "161b22"
CLR_BORDER:= "30363d"
CLR_MUTED := "6e7681"
CLR_TEXT  := "e6edf3"
CLR_ACCENT:= "79c0ff"
CLR_GREEN := "3fb950"
CLR_RED   := "f85149"

; ================================================================
; 配置
; ================================================================
LoadConfig() {
    server := IniRead(ConfigFile, "Config", "server", DefaultServer)
    apikey := IniRead(ConfigFile, "Config", "apikey", DefaultApiKey)
    autoQ  := IniRead(ConfigFile, "Config", "autoQuery", "1")
    if not FileExist(ConfigFile) {
        IniWrite(server, ConfigFile, "Config", "server")
        IniWrite(apikey, ConfigFile, "Config", "apikey")
        IniWrite(autoQ,  ConfigFile, "Config", "autoQuery")
    }
    return {server:server, apikey:apikey, autoQ:autoQ}
}
SaveConfig(server, apikey, autoQ) {
    IniWrite(server, ConfigFile, "Config", "server")
    IniWrite(apikey, ConfigFile, "Config", "apikey")
    IniWrite(autoQ,  ConfigFile, "Config", "autoQuery")
}

; ================================================================
; JSON 轻量提取
; ================================================================
JsonVal(json, key) {
    pattern := '"' . key . '"\s*:\s*("(?:[^"\\]|\\.)*"|true|false|null|-?\d+(?:\.\d+)?)'
    if RegExMatch(json, pattern, &m) {
        v := m[1]
        if SubStr(v,1,1) = '"'
            return SubStr(v, 2, StrLen(v)-2)
        return v
    }
    return ""
}
JsonArr(json, key) {
    s := InStr(json, '"' key '"')
    if !s
        return ""
    b := InStr(json, "[",, s)
    if !b
        return ""
    d := 0, r := ""
    loop parse SubStr(json, b) {
        if (A_LoopField = "[")
            d++
        else if (A_LoopField = "]")
            d--
        r .= A_LoopField
        if (d = 0)
            break
    }
    return r
}
ParseNames(arr) {
    n := [], p := 1
    while p := InStr(arr, '"name"',, p) {
        c := InStr(arr, ":",, p)
        q := InStr(arr, '"',, c+1)
        e := InStr(arr, '"',, q+1)
        if !q or !e
            break
        n.Push(SubStr(arr, q+1, e-q-1))
        p := e+1
    }
    return n
}

; ================================================================
; GUI
; ================================================================
G := Gui()
G.Opt("-Caption")
G.Title := "Minecraft 服务器状态查询"
G.BackColor := CLR_BG
G.SetFont("s10", "Microsoft YaHei")
G.MarginX := 0, G.MarginY := 0
TraySetIcon(A_ScriptDir "\Logo.ico")

; -- 1px 深色窗口描边 --
G.Add("Text", "x0 y0 w580 h1 Background30363d")
G.Add("Text", "x0 y569 w580 h1 Background30363d")
G.Add("Text", "x0 y0 w1 h570 Background30363d")
G.Add("Text", "x579 y0 w1 h570 Background30363d")

; -- title bar --
G.Add("Text", "x0 y0 w580 h34 Background" CLR_CARD)
G.Add("Text", "x12 y7 w20 h20 BackgroundTrans c9d1d9", "🌐")
G.Add("Text", "x34 y8 w496 h18 BackgroundTrans c9d1d9", "Minecraft 服务器状态查询")
BtnMin   := G.Add("Text", "x532 y5 w22 h22 Center BackgroundTrans c9d1d9", "─")
BtnClose := G.Add("Text", "x554 y5 w22 h22 Center BackgroundTrans c9d1d9", "✕")

; -- header --
Y := 44
G.Add("Text", "x0 y" Y " w580 h32 Center c" CLR_ACCENT, "🎮").SetFont("s20")
Y += 34
G.Add("Text", "x0 y" Y " w580 h26 Center c" CLR_ACCENT, "Minecraft 服务器状态").SetFont("s12 bold")
Y += 28
G.Add("Text", "x0 y" Y " w580 h18 Center c" CLR_MUTED, "配置自动保存 · 打开自动查询").SetFont("s9")
Y += 24

; -- 输入卡片 --
cardY := Y
CardBg := G.Add("Text", "x14 y" Y " w552 h140 Background" CLR_CARD)
Y += 14
G.Add("Text", "x26 y" Y " w528 h16 BackgroundTrans c9d1d9", "⚙ 服务器信息").SetFont("s9 bold")
Y += 24
G.Add("Text", "x26 y" Y " w46 h26 BackgroundTrans Right c9d1d9", "地址")
EditServer := G.Add("Edit", "x76 y" Y " w340 h26 -E0x200 Background0a0f1a c" CLR_TEXT)
Y += 34
G.Add("Text", "x26 y" Y " w46 h26 BackgroundTrans Right c9d1d9", "密钥")
EditApiKey := G.Add("Edit", "x76 y" Y " w340 h26 -E0x200 Background0a0f1a c" CLR_TEXT)
Y += 36
; 按钮 + 正方形复选框同行
BtnQuery  := G.Add("Text", "x76 y" Y " w165 h32 Center 0x200 BackgroundTrans c9d1d9", "🔍 查询服务器状态")
BtnGetKey := G.Add("Text", "x248 y" Y " w105 h32 Center 0x200 BackgroundTrans c9d1d9", "获取密钥")
ChkBox    := G.Add("Text", "x362 y" Y+7 " w18 h18 Center 0x200 Background0A0F1A c9d1d9", "✓")
ChkBox.SetFont("s9")
ChkLabel  := G.Add("Text", "x383 y" Y+8 " w130 h16 0x200 BackgroundTrans c9d1d9", "打开时自动查询")
ChkLabel.SetFont("s9")
ChkBox.OnEvent("Click", (*) => ChkBox.Text := (ChkBox.Text="✓" ? "" : "✓"))
ChkLabel.OnEvent("Click", (*) => ChkBox.Text := (ChkBox.Text="✓" ? "" : "✓"))
Y += 42
cardH := Y - cardY + 6
CardBg.Move(, cardY, 552, cardH)
Y += 10

; -- 错误 --
ErrText := G.Add("Text", "x14 y" Y " w552 h22 Hidden c" CLR_RED)
ErrText.SetFont("s9")
Y += 10

; -- 结果区域 --
resY := Y
ResBg := G.Add("Text", "x14 y" Y " w552 h240 Hidden Background" CLR_CARD)

ResLine1 := G.Add("Text", "x24 y" resY+14 " w532 h22 Hidden c" CLR_TEXT)
ResLine1.SetFont("s12 bold")
ResSep1  := G.Add("Text", "x24 y" resY+40 " w532 h1 Hidden Background" CLR_BORDER)
ResLine2 := G.Add("Text", "x24 y" resY+50 " w260 h20 Hidden c" CLR_TEXT)
ResLine3 := G.Add("Text", "x24 y" resY+74 " w260 h20 Hidden c" CLR_TEXT)
ResLine4 := G.Add("Text", "x290 y" resY+50 " w260 h20 Hidden c" CLR_TEXT)
ResLine5 := G.Add("Text", "x290 y" resY+74 " w260 h20 Hidden c" CLR_TEXT)
ResSep2  := G.Add("Text", "x24 y" resY+100 " w532 h1 Hidden Background" CLR_BORDER)
ResMotdH := G.Add("Text", "x24 y" resY+108 " w532 h16 Hidden c9d1d9")
ResMotdH.SetFont("s9 bold")
ResMotd  := G.Add("Text", "x24 y" resY+128 " w532 h36 Hidden c9d1d9")
ResMotd.SetFont("s9")
ResSep3  := G.Add("Text", "x24 y" resY+168 " w532 h1 Hidden Background" CLR_BORDER)
ResPlH   := G.Add("Text", "x24 y" resY+176 " w532 h16 Hidden c9d1d9")
ResPlH.SetFont("s10 bold")
ResPlayers := G.Add("Text", "x24 y" resY+196 " w532 h36 Hidden c9d1d9")
ResPlayers.SetFont("s10")
ResFoot  := G.Add("Text", "x24 y" resY+234 " w532 h18 Hidden c" CLR_MUTED)
ResFoot.SetFont("s9")

; -- 底部 --
G.Add("Text", "x0 y568 w580 h16 Center c6e7681", "uapis.cn  ·  server-config.ini").SetFont("s9")

; ========== 控件数组方便操作 ==========
ResCtrls := [ResBg, ResLine1, ResSep1, ResLine2, ResLine3, ResLine4, ResLine5,
             ResSep2, ResMotdH, ResMotd, ResSep3, ResPlH, ResPlayers, ResFoot]

; ================================================================
; 事件
; ================================================================
; 拖拽 - 标题栏区域按住可拖动，不拦截按钮点击
WM_LBUTTONDOWN(w, l, m, h) {
    if (h = G.Hwnd) {
        x := l & 0xFFFF, y := l >> 16
        if (y <= 34 && x < 520)
            PostMessage(0xA1, 2, 0, h)  ; 发起拖拽
    }
}
OnMessage(0x0201, WM_LBUTTONDOWN)

BtnClose.OnEvent("Click", (*) => ExitApp())
BtnMin.OnEvent("Click",   (*) => WinMinimize("ahk_id " G.Hwnd))
BtnGetKey.OnEvent("Click", (*) => Run("https://uapis.cn/console/api-keys"))
BtnQuery.OnEvent("Click",  DoQuery)

; ================================================================
; 查询
; ================================================================
DoQuery(*) {
    server := Trim(EditServer.Text)
    if (server = "") {
        ErrText.Visible := true
        ErrText.Move(, resY, 552, 20)
        ErrText.Text := "❌ 请先输入服务器地址"
        HideResult()
        return
    }
    ErrText.Visible := false

    apikey := Trim(EditApiKey.Text)
    autoQ  := (ChkBox.Text="✓") ? "1" : "0"
    SaveConfig(server, apikey, autoQ)

    ; loading
    ShowResult()
    ResLine1.Text := "⏳ 正在查询 " server " ..."
    ResLine1.Move(, resY+14, 532, 22)
    HideDetail()

    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    url := "https://uapis.cn/api/v1/game/minecraft/serverstatus?server=" server
    ok := true, json := ""
    try {
        whr.Open("GET", url, true)
        whr.SetTimeouts(15000,15000,15000,15000)
        if (apikey != "")
            whr.SetRequestHeader("Authorization", "Bearer " apikey)
        whr.Send()
        whr.WaitForResponse()
        json := whr.ResponseText
    } catch as e {
        ok := false
        json := e.Message
    }
    if !ok {
        ResLine1.Text := "❌ 请求失败: " json
        return
    }

    ; parse
    online := JsonVal(json, "online") = "true"
    ip     := JsonVal(json, "ip")
    if (ip = "")
        ip := "-"
    port   := JsonVal(json, "port")
    portStr := (port = "" || port = "25565") ? "25565" : port
    ver    := JsonVal(json, "version")
    if (ver = "")
        ver := "-"
    pl     := JsonVal(json, "players")
    if (pl = "")
        pl := "-"
    maxPl  := JsonVal(json, "max_players")
    if (maxPl = "")
        maxPl := "-"
    motd   := JsonVal(json, "motd_clean")
    if (motd = "")
        motd := "-"
    motdH  := JsonVal(json, "motd_html")
    names  := ParseNames(JsonArr(json, "online_players"))

    ; render
    stIcon := online ? "🟢" : "🔴"
    stText := online ? "在线" : "离线"
    ResLine1.Text := stIcon "  " stText "  ·  " server
    ResLine1.Move(, resY+14, 532, 22)

    ResLine2.Text := "👥  " pl " / " maxPl
    ResLine3.Text := "📦  " ver
    ResLine4.Text := "🌐  " ip ":" portStr
    ResLine5.Text := ""
    ResMotdH.Text := "MOTD"
    ResMotd.Text  := motd
    ; Adjust MOTD height based on content length
    motdLines := 1
    loop parse motd, "`n", "`r"
        motdLines++
    motdHt := Min(60, motdLines * 16 + 4)
    ResMotd.Move(, resY+128, 532, motdHt)

    ; players
    if (names.Length > 0) {
        plText := ""
        maxShow := Min(names.Length, 20)
        loop maxShow
            plText .= names[A_Index] . "  "
        if (names.Length > 20)
            plText .= "  ...还有" (names.Length-20) "人"
        ResPlH.Text := "在线玩家 (" names.Length ")"
        ResPlayers.Text := plText
        playersHt := Min(44, Ceil(maxShow/4)*18)
        ResPlayers.Move(, resY+196, 532, playersHt)
    } else {
        ResPlH.Text := ""
        ResPlayers.Text := ""
    }

    tm := FormatTime(, "HH:mm:ss")
    ResFoot.Text := "✔ 查询完成 · " tm " · 配置已保存"
    ResFoot.Move(, resY+234, 532, 18)

    ShowDetail()
    G.Show("w580 h590")
}

ShowResult() {
    for c in ResCtrls
        c.Visible := true
    ResBg.Move(, resY, 552, 240)
}
HideResult() {
    for c in ResCtrls
        c.Visible := false
}
HideDetail() {
    ResSep1.Visible  := false, ResLine2.Visible := false
    ResLine3.Visible := false, ResLine4.Visible := false
    ResLine5.Visible := false, ResSep2.Visible  := false
    ResMotdH.Visible := false, ResMotd.Visible  := false
    ResSep3.Visible  := false, ResPlH.Visible   := false
    ResPlayers.Visible:=false, ResFoot.Visible  := false
}
ShowDetail() {
    ResSep1.Visible  := true, ResLine2.Visible := true
    ResLine3.Visible := true, ResLine4.Visible := true
    ResSep2.Visible  := true, ResMotdH.Visible := true
    ResMotd.Visible  := true, ResFoot.Visible  := true
    if (ResPlH.Text != "") {
        ResSep3.Visible := true, ResPlH.Visible := true
        ResPlayers.Visible := true
    }
}

; ================================================================
; 启动
; ================================================================
cfg := LoadConfig()
EditServer.Value := cfg.server
EditApiKey.Value := cfg.apikey
ChkBox.Text := (cfg.autoQ = "1" ? "✓" : "")

G.Show("w580 h300")

if ((ChkBox.Text="✓") && Trim(EditServer.Text) != "")
    SetTimer(DoQuery, -500)

Persistent()
