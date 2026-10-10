--// Terminal Key System v3 (key system only)
--// Junkie Development keys + macOS-style window + boot animation + mobile layout
local CONFIG = {
	-- fill these from your Junkie Development dashboard
	Service    = "ARIO COOL",
	Identifier = "12116157",
	Provider   = "ARIO COOL",
	SdkUrl     = "https://jnkie.com/sdk/library.lua",

	SaveFile = "ariokey.txt",
	Title    = "ario@keysystem:~",
	Logo     = "ARIOSCRIPT",
}

local function onSuccess()
	-- hands control back to the Ario loader (opens the main window)
	local Ario = (getgenv and getgenv().Ario) or _G.Ario
	if Ario and Ario.OnKeyValid then
		Ario.OnKeyValid()
	end
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// junkie adapter (only place that talks to the SDK)
local Junkie
local function loadJunkie()
	if Junkie then return Junkie end
	local ok, lib = pcall(function() return loadstring(game:HttpGet(CONFIG.SdkUrl))() end)
	if ok and type(lib) == "table" then
		lib.service = CONFIG.Service
		lib.identifier = CONFIG.Identifier
		lib.provider = CONFIG.Provider
		Junkie = lib
	end
	return Junkie
end

local function validate(key)
	local lib = loadJunkie()
	if not lib then return false, "could not load the Junkie SDK" end
	local ok, res = pcall(lib.check_key, key)
	if not ok then return false, "check failed: " .. tostring(res) end
	if type(res) == "table" then
		local valid = res.valid == true
		return valid, res.message or res.error or (valid and "key accepted" or "invalid key")
	end
	return res == true, res == true and "key accepted" or "invalid key"
end

local function getKeyLink()
	local lib = loadJunkie()
	if not lib then return nil end
	local ok, link = pcall(lib.get_key_link)
	if ok and type(link) == "string" then return link end
end

--// file helpers
local function readSaved()
	if isfile and readfile and isfile(CONFIG.SaveFile) then
		local ok, data = pcall(readfile, CONFIG.SaveFile)
		if ok then return (data:gsub("%s+", "")) end
	end
end

local function saveKey(key)
	if writefile then pcall(writefile, CONFIG.SaveFile, key) end
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

--// layout (desktop vs mobile)
local camera = workspace.CurrentCamera
local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
local MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local W = MOBILE and math.clamp(vp.X - 24, 280, 460) or 540
local H = MOBILE and math.clamp(math.floor(vp.Y * 0.55), 210, 300) or 330
local TEXT = MOBILE and 15 or 14
local BAR_H = MOBILE and 40 or 32
local NORMAL_SIZE = UDim2.fromOffset(W, H)
local NORMAL_POS = MOBILE and UDim2.new(0.5, 0, 0, 44) or UDim2.new(0.5, 0, 0.5, -H / 2)
local BIG_W = MOBILE and (vp.X - 16) or math.min(vp.X * 0.85, 900)
local BIG_H = MOBILE and math.clamp(vp.Y * 0.75, H, 520) or math.min(vp.Y * 0.85, 600)
local BIG_SIZE = UDim2.fromOffset(BIG_W, BIG_H)
local BIG_POS = MOBILE and UDim2.new(0.5, 0, 0, 30) or UDim2.new(0.5, 0, 0.5, -BIG_H / 2)

--// palette
local BG     = Color3.fromRGB(13, 13, 15)
local GREEN  = Color3.fromRGB(80, 250, 123)
local RED    = Color3.fromRGB(255, 85, 85)
local YELLOW = Color3.fromRGB(241, 250, 140)
local CYAN   = Color3.fromRGB(139, 233, 253)
local GREY   = Color3.fromRGB(140, 140, 140)

--// gui root
local parent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "ArioKeySystem"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = parent

-- invisible backdrop: clicking outside the window = window loses focus (like macOS)
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.ZIndex = 0
backdrop.Parent = gui

local main = Instance.new("CanvasGroup") -- clips children to rounded corners, fades as one
main.AnchorPoint = Vector2.new(0.5, 0)
main.Size = NORMAL_SIZE
main.Position = NORMAL_POS
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.GroupTransparency = 1
main.Active = true -- sinks clicks so the backdrop only sees outside clicks
main.ZIndex = 2
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(70, 70, 76)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local scale = Instance.new("UIScale", main)
scale.Scale = 0.8

--// macOS titlebar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, BAR_H)
bar.BackgroundColor3 = Color3.new(1, 1, 1)
bar.BorderSizePixel = 0
bar.ZIndex = 20
bar.Parent = main
local barGrad = Instance.new("UIGradient", bar)
barGrad.Rotation = 90
barGrad.Color = ColorSequence.new(Color3.fromRGB(54, 54, 58), Color3.fromRGB(40, 40, 44))

local sep = Instance.new("Frame") -- 1px divider under the titlebar
sep.AnchorPoint = Vector2.new(0, 1)
sep.Size = UDim2.new(1, 0, 0, 1)
sep.Position = UDim2.new(0, 0, 1, 0)
sep.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sep.BackgroundTransparency = 0.35
sep.BorderSizePixel = 0
sep.ZIndex = 21
sep.Parent = bar

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.5)
title.Size = UDim2.new(1, -170, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamMedium
title.TextSize = TEXT
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Text = CONFIG.Title
title.ZIndex = 20
title.Parent = bar

-- traffic lights: real macOS colours, glyphs appear when hovering the group,
-- all three turn grey when the window is not focused
local DOT = MOBILE and 16 or 12
local HIT = MOBILE and 30 or 18
local STEP = MOBILE and 30 or 20
local LINE = MOBILE and 2 or 1

local focused, hovered = true, false
local dots = {}

local function makeDot(color, kind, index)
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromOffset(HIT, HIT)
	hit.AnchorPoint = Vector2.new(0, 0.5)
	hit.Position = UDim2.new(0, 6 + (index - 1) * STEP, 0.5, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 22
	hit.Parent = bar

	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(DOT, DOT)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.ZIndex = 23
	dot.Parent = hit
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local ds = Instance.new("UIStroke", dot)
	ds.Color = Color3.new(0, 0, 0)
	ds.Transparency = 0.8
	ds.Thickness = 1

	local ink = Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)
	local glyph = Instance.new("Frame")
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.ZIndex = 24
	glyph.Parent = dot
	local function line(w, h, rot)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromOffset(w, h)
		f.Rotation = rot or 0
		f.BackgroundColor3 = ink
		f.BorderSizePixel = 0
		f.ZIndex = 24
		f.Parent = glyph
	end
	local len = math.floor(DOT * 0.6)
	if kind == "close" then
		line(len + 1, LINE, 45)
		line(len + 1, LINE, -45)
	elseif kind == "min" then
		line(len, LINE)
	else
		line(len, LINE)
		line(LINE, len)
	end

	local d = { hit = hit, dot = dot, glyph = glyph, color = color }
	dots[#dots + 1] = d
	return hit
end

local function refreshDots()
	for _, d in ipairs(dots) do
		d.dot.BackgroundColor3 = (focused or hovered) and d.color or Color3.fromRGB(78, 78, 82)
		d.glyph.Visible = MOBILE or hovered
	end
	title.TextColor3 = focused and Color3.fromRGB(215, 215, 220) or Color3.fromRGB(120, 120, 126)
end

local dotClose = makeDot(Color3.fromRGB(255, 95, 87), "close", 1)
local dotMin   = makeDot(Color3.fromRGB(254, 188, 46), "min", 2)
local dotMax   = makeDot(Color3.fromRGB(40, 200, 64), "max", 3)

local hoverCount = 0
for _, d in ipairs(dots) do
	d.hit.MouseEnter:Connect(function() hoverCount += 1; hovered = true; refreshDots() end)
	d.hit.MouseLeave:Connect(function()
		hoverCount -= 1
		task.defer(function()
			if hoverCount <= 0 then hoverCount = 0; hovered = false; refreshDots() end
		end)
	end)
end
refreshDots()

backdrop.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		focused = false
		refreshDots()
	end
end)
main.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		focused = true
		refreshDots()
	end
end)

--// body
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -BAR_H)
body.Position = UDim2.fromOffset(0, BAR_H)
body.BackgroundTransparency = 1
body.Parent = main

local log = Instance.new("ScrollingFrame")
log.Size = UDim2.new(1, -20, 1, -62)
log.Position = UDim2.fromOffset(10, 8)
log.BackgroundTransparency = 1
log.BorderSizePixel = 0
log.ScrollBarThickness = 3
log.CanvasSize = UDim2.new()
log.AutomaticCanvasSize = Enum.AutomaticSize.Y
log.Parent = body
local layout = Instance.new("UIListLayout", log)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)

local row = Instance.new("Frame")
row.AnchorPoint = Vector2.new(0, 1)
row.Size = UDim2.new(1, -20, 0, 38)
row.Position = UDim2.new(0, 10, 1, -8)
row.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
row.BorderSizePixel = 0
row.Parent = body
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(0, 24, 1, 0)
promptLabel.Position = UDim2.fromOffset(4, 0)
promptLabel.BackgroundTransparency = 1
promptLabel.Font = Enum.Font.Code
promptLabel.TextSize = TEXT + 1
promptLabel.TextColor3 = GREEN
promptLabel.Text = ">"
promptLabel.Parent = row

local function makeBtn(text, w, offset, color)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Size = UDim2.fromOffset(w, 28)
	b.Position = UDim2.new(1, offset, 0.5, 0)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Font = Enum.Font.Code
	b.TextSize = TEXT - 1
	b.TextColor3 = Color3.fromRGB(10, 10, 10)
	b.Text = text
	b.Parent = row
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local enterBtn  = makeBtn("Enter", 54, -5, GREEN)
local getKeyBtn = makeBtn("Get Key", 70, -63, CYAN)

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -28 - 138, 1, 0)
input.Position = UDim2.fromOffset(28, 0)
input.BackgroundTransparency = 1
input.ClearTextOnFocus = false
input.Font = Enum.Font.Code
input.TextSize = TEXT + 1
input.TextColor3 = Color3.fromRGB(235, 235, 235)
input.PlaceholderText = "paste your key"
input.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
input.TextXAlignment = Enum.TextXAlignment.Left
input.ClipsDescendants = true
input.Text = ""
input.Parent = row

--// output
local order = 0
local function print_(text, color, typed)
	order += 1
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, -6, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextSize = TEXT
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	l.Text = typed and "" or text
	l.Parent = log
	local function down() log.CanvasPosition = Vector2.new(0, 1e6) end
	if typed then
		for i = 1, #text do
			if not l.Parent then return end
			l.Text = text:sub(1, i)
			down()
			task.wait(0.012)
		end
	else
		task.defer(down)
	end
end

--// window actions
local closing, minimized, maximized = false, false, false

local function closeGui()
	if closing then return end
	closing = true
	tween(scale, 0.25, { Scale = 0.85 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(main, 0.25, { GroupTransparency = 1 })
	task.delay(0.3, function() gui:Destroy() end)
end

local function applyShape()
	if minimized then
		tween(main, 0.25, { Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, BAR_H) })
	else
		tween(main, 0.3, { Size = maximized and BIG_SIZE or NORMAL_SIZE }, Enum.EasingStyle.Quint)
	end
end

local function toggleMinimize()
	minimized = not minimized
	if minimized then
		applyShape()
		task.delay(0.25, function() if minimized then body.Visible = false end end)
	else
		body.Visible = true
		applyShape()
	end
end

local function toggleZoom()
	if minimized then
		minimized = false
		body.Visible = true
	end
	maximized = not maximized
	tween(main, 0.3, { Position = maximized and BIG_POS or NORMAL_POS }, Enum.EasingStyle.Quint)
	applyShape()
end

dotClose.MouseButton1Click:Connect(closeGui)
dotMin.MouseButton1Click:Connect(toggleMinimize)
dotMax.MouseButton1Click:Connect(toggleZoom)

--// drag + double-click titlebar to zoom (like macOS)
do
	local dragging, startPos, startInput, moved, lastClick = false, nil, nil, false, 0
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved, startPos, startInput = true, false, main.Position, i.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved then
						if os.clock() - lastClick < 0.35 then
							lastClick = 0
							toggleZoom()
						else
							lastClick = os.clock()
						end
					end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startInput
			if d.Magnitude > 4 then moved = true end
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

--// shake on wrong key
local function shake()
	local base = main.Position
	for _, off in ipairs({ -8, 8, -5, 5, 0 }) do
		tween(main, 0.04, { Position = base + UDim2.fromOffset(off, 0) })
		task.wait(0.045)
	end
	main.Position = base
end

--// key logic
local busy, done = false, false

local function checkKey(key)
	if busy or done then return end
	busy = true
	print_("[*] validating key with Junkie...", YELLOW)
	local valid, msg = validate(key)
	if valid then
		done = true
		saveKey(key)
		print_("[+] " .. tostring(msg), GREEN)
		print_("[+] loading script...", GREEN)
		task.wait(0.8)
		closeGui()
		task.spawn(onSuccess)
	else
		print_("[-] " .. tostring(msg), RED)
		task.spawn(shake)
		busy = false
	end
end

local function getKey()
	print_("[*] requesting key link...", YELLOW)
	local link = getKeyLink()
	if not link then
		print_("[-] could not get the key link", RED)
		return
	end
	if setclipboard then
		setclipboard(link)
		print_("[+] link copied: " .. link, GREEN)
	else
		print_("[!] open this link: " .. link, YELLOW)
	end
end

local commands = {
	help = function()
		print_("commands:", CYAN)
		print_("  getkey       copy your Junkie key link", CYAN)
		print_("  key <key>    validate a key (or just paste it)", CYAN)
		print_("  clear        clear the terminal", CYAN)
		print_("  exit         close", CYAN)
	end,
	getkey = getKey,
	clear = function()
		for _, c in ipairs(log:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
	end,
	exit = closeGui,
}

local function submit()
	local text = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
	input.Text = ""
	if text == "" then return end
	print_("> " .. text, Color3.fromRGB(150, 150, 150))
	local cmd, arg = text:match("^(%S+)%s*(.*)$")
	cmd = cmd:lower()
	if cmd == "key" then
		if arg == "" then print_("[-] usage: key <key>", RED) else checkKey(arg) end
	elseif commands[cmd] then
		commands[cmd]()
	else
		checkKey(text)
	end
end

input.FocusLost:Connect(function(enter)
	if enter then
		submit()
		if not MOBILE then input:CaptureFocus() end
	end
end)
enterBtn.MouseButton1Click:Connect(submit)
getKeyBtn.MouseButton1Click:Connect(getKey)

--// boot animation
local boot = Instance.new("CanvasGroup")
boot.Size = UDim2.new(1, 0, 1, -BAR_H)
boot.Position = UDim2.fromOffset(0, BAR_H)
boot.BackgroundColor3 = BG
boot.BorderSizePixel = 0
boot.ZIndex = 10
boot.Parent = main

local logo = Instance.new("TextLabel")
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Position = UDim2.new(0.5, 0, 0.36, 0)
logo.Size = UDim2.new(1, 0, 0, 44)
logo.BackgroundTransparency = 1
logo.Font = Enum.Font.Code
logo.TextSize = MOBILE and 28 or 36
logo.TextColor3 = GREEN
logo.Text = ""
logo.ZIndex = 11
logo.Parent = boot
local logoStroke = Instance.new("UIStroke", logo)
logoStroke.Color = GREEN
logoStroke.Thickness = 1.5
logoStroke.Transparency = 0.7

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.new(0.5, 0, 0.58, 0)
status.Size = UDim2.new(1, -20, 0, 20)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextSize = TEXT
status.TextColor3 = GREY
status.Text = ""
status.ZIndex = 11
status.Parent = boot

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0.5)
track.Position = UDim2.new(0.5, 0, 0.7, 0)
track.Size = UDim2.new(0.6, 0, 0, 5)
track.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
track.BorderSizePixel = 0
track.ZIndex = 11
track.Parent = boot
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.ZIndex = 12
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local grad = Instance.new("UIGradient", fill)
grad.Color = ColorSequence.new(GREEN, CYAN)

local spin = { "|", "/", "-", "\\" }
local spinning, label = true, ""
task.spawn(function()
	local i = 0
	while spinning and boot.Parent do
		i = i % #spin + 1
		status.Text = spin[i] .. " " .. label
		task.wait(0.09)
	end
end)

task.spawn(function() -- glow pulse while booting
	while spinning and boot.Parent do
		tween(logoStroke, 0.7, { Transparency = 0.2 }, Enum.EasingStyle.Sine)
		task.wait(0.7)
		tween(logoStroke, 0.7, { Transparency = 0.8 }, Enum.EasingStyle.Sine)
		task.wait(0.7)
	end
end)

-- window pops in
tween(main, 0.35, { GroupTransparency = 0 })
tween(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)

task.spawn(function()
	for i = 1, #CONFIG.Logo do
		logo.Text = CONFIG.Logo:sub(1, i) .. (i < #CONFIG.Logo and "_" or "")
		task.wait(0.06)
	end
	local glitch = "#$%&@*"
	for _ = 1, 5 do
		local chars = {}
		for c in CONFIG.Logo:gmatch(".") do
			chars[#chars + 1] = math.random() < 0.25 and glitch:sub(math.random(#glitch), math.random(#glitch)) or c
		end
		logo.Text = table.concat(chars)
		task.wait(0.05)
	end
	logo.Text = CONFIG.Logo

	local sdkOk = false
	local stages = {
		{ "initializing", 0.25 },
		{ "loading junkie sdk", 0.6, function() sdkOk = loadJunkie() ~= nil end },
		{ "checking environment", 0.85 },
		{ "ready", 1 },
	}
	for _, s in ipairs(stages) do
		label = s[1]
		tween(fill, 0.5, { Size = UDim2.new(s[2], 0, 1, 0) })
		if s[3] then s[3]() end
		task.wait(0.55)
	end
	spinning = false
	status.Text = "* ready"
	status.TextColor3 = GREEN
	task.wait(0.3)

	tween(boot, 0.4, { GroupTransparency = 1 })
	task.wait(0.4)
	boot:Destroy()

	print_("Key System v3.0 - powered by Junkie", GREEN, true)
	print_("type 'help' for commands, or paste your key.", GREY, true)
	if not sdkOk then
		print_("[-] Junkie SDK failed to load. Check SdkUrl and your connection.", RED)
	elseif CONFIG.Service == "YOUR_SERVICE" then
		print_("[!] fill in Service / Identifier / Provider in CONFIG.", YELLOW)
	end
	if not MOBILE then input:CaptureFocus() end

	local saved = readSaved()
	if saved and saved ~= "" and sdkOk then
		print_("[*] saved key found", YELLOW)
		checkKey(saved)
	end
end)
