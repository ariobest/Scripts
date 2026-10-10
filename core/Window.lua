--// Ario Window library (macOS-style, tabs, draggable, mobile friendly)
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local BG, SIDE, ITEM = Color3.fromRGB(13, 13, 15), Color3.fromRGB(20, 20, 23), Color3.fromRGB(30, 30, 34)
local GREEN, TEXTC, GREY = Color3.fromRGB(80, 250, 123), Color3.fromRGB(225, 225, 230), Color3.fromRGB(140, 140, 146)

local Window = {}
Window.__index = Window

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end

function Window.new(opts)
	opts = opts or {}
	local self = setmetatable({ tabs = {}, current = nil }, Window)
	local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
	local W = mobile and math.clamp(vp.X - 24, 300, 520) or 560
	local H = mobile and math.clamp(vp.Y * 0.7, 260, 420) or 360

	self.gui = new("ScreenGui", { Name = "ArioWindow", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998 })
	self.gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

	self.main = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, BorderSizePixel = 0, GroupTransparency = 1,
	}, self.gui)
	round(self.main, 10)
	new("UIStroke", { Color = Color3.fromRGB(70, 70, 76), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, self.main)
	local scale = new("UIScale", { Scale = 0.85 }, self.main)

	local barH = mobile and 40 or 32
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, barH), BackgroundColor3 = Color3.fromRGB(44, 44, 48), BorderSizePixel = 0, ZIndex = 5 }, self.main)
	new("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(75, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = TEXTC, Text = opts.Title or "ario", ZIndex = 6,
	}, bar)

	self.body = new("Frame", { Size = UDim2.new(1, 0, 1, -barH), Position = UDim2.fromOffset(0, barH), BackgroundTransparency = 1 }, self.main)
	local sideW = mobile and 100 or 130
	self.side = new("ScrollingFrame", {
		Size = UDim2.new(0, sideW, 1, 0), BackgroundColor3 = SIDE, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, self.body)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, self.side)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, self.side)
	self.content = new("Frame", { Size = UDim2.new(1, -sideW, 1, 0), Position = UDim2.fromOffset(sideW, 0), BackgroundTransparency = 1 }, self.body)

	-- traffic lights
	local function dot(color, x, fn)
		local b = new("TextButton", { Size = UDim2.fromOffset(mobile and 16 or 12, mobile and 16 or 12), Position = UDim2.new(0, x, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = color, Text = "", AutoButtonColor = false, ZIndex = 7 }, bar)
		round(b, 99)
		b.MouseButton1Click:Connect(fn)
	end
	local step = mobile and 26 or 20
	dot(Color3.fromRGB(255, 95, 87), 12, function() self:Destroy() end)
	dot(Color3.fromRGB(254, 188, 46), 12 + step, function() self.body.Visible = not self.body.Visible
		TweenService:Create(self.main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = self.body.Visible and UDim2.fromOffset(W, H) or UDim2.fromOffset(W, barH) }):Play() end)
	dot(Color3.fromRGB(40, 200, 64), 12 + step * 2, function() end)

	-- drag
	local dragging, start, startPos
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, startPos = true, i.Position, self.main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	self.conn = UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			self.main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	TweenService:Create(self.main, TweenInfo.new(0.35), { GroupTransparency = 0 }):Play()
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	return self
end

function Window:Destroy()
	if self.conn then self.conn:Disconnect() end
	self.gui:Destroy()
end

function Window:Tab(name)
	local tab = { window = self }
	tab.btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = ITEM, BackgroundTransparency = 1, AutoButtonColor = false,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = GREY, Text = name, LayoutOrder = #self.tabs + 1 }, self.side)
	round(tab.btn, 6)
	tab.page = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, self.content)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tab.page)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8) }, tab.page)

	local function row(h)
		local f = new("Frame", { Size = UDim2.new(1, 0, 0, h or 34), BackgroundColor3 = ITEM, BorderSizePixel = 0 }, tab.page)
		round(f, 6)
		return f
	end
	local function label(parent, text)
		return new("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TEXTC, TextXAlignment = Enum.TextXAlignment.Left, Text = text }, parent)
	end

	function tab:Label(text)
		local f = row(26); f.BackgroundTransparency = 1
		local l = label(f, text); l.TextColor3 = GREY; l.Size = UDim2.new(1, -10, 1, 0)
		return { Set = function(_, t) l.Text = t end }
	end
	function tab:Button(text, cb)
		local f = row()
		label(f, text)
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
		b.MouseButton1Click:Connect(function() if cb then task.spawn(cb) end end)
	end
	function tab:Toggle(text, default, cb)
		local f = row()
		label(f, text)
		local state = default == true
		local pill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(36, 18), BorderSizePixel = 0 }, f)
		round(pill, 99)
		local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, pill)
		round(knob, 99)
		local function render()
			TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundColor3 = state and GREEN or Color3.fromRGB(60, 60, 66) }):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(0, state and 20 or 2, 0.5, 0) }):Play()
		end
		render()
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
		b.MouseButton1Click:Connect(function() state = not state; render(); if cb then task.spawn(cb, state) end end)
	end

	local function select()
		if self.current then
			self.current.page.Visible = false
			self.current.btn.BackgroundTransparency = 1
			self.current.btn.TextColor3 = GREY
		end
		self.current = tab
		tab.page.Visible = true
		tab.btn.BackgroundTransparency = 0
		tab.btn.TextColor3 = GREEN
	end
	tab.btn.MouseButton1Click:Connect(select)
	self.tabs[#self.tabs + 1] = tab
	if #self.tabs == 1 then select() end
	return tab
end

return Window
