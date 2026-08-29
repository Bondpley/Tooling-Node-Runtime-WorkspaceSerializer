--==========================================================================--
--                Tooling Node Runtime WorkspaceSerializer                  --
------------------------------------------------------------------------------
--   https://github.com/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer   --
--                              By Bond_pley                                --
--==========================================================================--

return function(webhookUrl)
local WEBHOOK_URL = webhookUrl or ""

local http = game:GetService("HttpService")
local plrs = game:GetService("Players")
local tw = game:GetService("TweenService")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local lp = plrs.LocalPlayer
if not lp then return end

local MAX_CHUNK = 180000
local AUTO_SAVE = 300
local YIELD_EVERY = 9999
local PREVIEW_MAX = 100000

local BG = Color3.new(0, 0, 0)
local PANEL = Color3.fromRGB(30, 30, 30)
local ACC = Color3.new(1, 1, 1)
local ACC2 = Color3.fromRGB(200, 200, 200)
local TXT = Color3.new(1, 1, 1)
local MUTED = Color3.fromRGB(160, 160, 160)
local BORDER = Color3.fromRGB(60, 60, 60)

local SND_CLICK = "rbxassetid://6895079853"
local SND_SUC = "rbxassetid://17692186009"
local SND_HOVER = "rbxassetid://139800881181209"

local function playSnd(par, id, vol)
	if id == "rbxassetid://0" then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol or 0.7
	s.Parent = par
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

local function isOwned(inst)
	if inst:IsDescendantOf(plrs) then return true end
	if inst == workspace.CurrentCamera then return true end
	for _, p in ipairs(plrs:GetPlayers()) do
		local c = p.Character
		if c and inst:IsDescendantOf(c) then return true end
		local b = p:FindFirstChild("Backpack")
		if b and inst:IsDescendantOf(b) then return true end
		local g = p:FindFirstChild("PlayerGui")
		if g and inst:IsDescendantOf(g) then return true end
	end
	return false
end

local function ser(v)
	local t = typeof(v)
	if t == "Vector3" then
		return {"V3", v.X, v.Y, v.Z}
	elseif t == "Color3" then
		return {"C3", v.R, v.G, v.B}
	elseif t == "UDim2" then
		return {"UD2", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset}
	elseif t == "BrickColor" then
		return {"BC", v.Number}
	elseif t == "NumberRange" then
		return {"NR", v.Min, v.Max}
	elseif t == "EnumItem" then
		return {"EN", tostring(v.EnumType), v.Name}
	elseif t == "CFrame" then
		local p, l, u = v.Position, v.LookVector, v.UpVector
		return {"CF", p.X, p.Y, p.Z, l.X, l.Y, l.Z, u.X, u.Y, u.Z}
	elseif t == "Instance" then
		if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
			return {"SCRIPT", v.Name}
		end
		return nil
	elseif t == "Rect" then
		return {"RECT", v.Min.X, v.Min.Y, v.Max.X, v.Max.Y}
	elseif t == "Vector2" then
		return {"V2", v.X, v.Y}
	elseif t == "PhysicalProperties" then
		return {"PP", v.Density, v.Friction, v.Elasticity, v.FrictionWeight, v.ElasticityWeight}
	elseif t == "FontFace" then
		return {"FF", v.Family, v.Weight, v.Style}
	elseif t == "NumberSequence" then
		local keys = {}
		for i, kp in ipairs(v.Keypoints) do
			keys[i] = {kp.Time, kp.Value, kp.Envelope}
		end
		return {"NS", keys}
	elseif t == "ColorSequence" then
		local keys = {}
		for i, kp in ipairs(v.Keypoints) do
			keys[i] = {kp.Time, kp.Value.R, kp.Value.G, kp.Value.B}
		end
		return {"CS", keys}
	elseif t == "Ray" then
		return {"RAY", v.Origin.X, v.Origin.Y, v.Origin.Z, v.Direction.X, v.Direction.Y, v.Direction.Z}
	elseif t == "Region3" then
		return {"R3", v.Min.X, v.Min.Y, v.Min.Z, v.Max.X, v.Max.Y, v.Max.Z}
	elseif t == "Vector3int16" then
		return {"V3I", v.X, v.Y, v.Z}
	elseif t == "Vector2int16" then
		return {"V2I", v.X, v.Y}
	elseif t == "UDim" then
		return {"UD", v.Scale, v.Offset}
	else
		return nil
	end
end

local function des(d)
	if type(d) ~= "table" then return d end
	local tag = d[1]
	if tag == "V3" then
		return Vector3.new(d[2], d[3], d[4])
	elseif tag == "C3" then
		return Color3.new(d[2], d[3], d[4])
	elseif tag == "UD2" then
		return UDim2.new(d[2], d[3], d[4], d[5])
	elseif tag == "BC" then
		return BrickColor.new(d[2])
	elseif tag == "NR" then
		return NumberRange.new(d[2], d[3])
	elseif tag == "EN" then
		local e = Enum[d[2]]
		if e then return e[d[3]] end
		return nil
	elseif tag == "CF" then
		local p = Vector3.new(d[2], d[3], d[4])
		local l = Vector3.new(d[5], d[6], d[7])
		local u = Vector3.new(d[8], d[9], d[10])
		local ok, cf = pcall(function() return CFrame.lookAt(p, p + l, u) end)
		return ok and cf or CFrame.new(p)
	elseif tag == "SCRIPT" then
		local s = Instance.new("Script")
		s.Name = d[2]
		s.Source = "-- Placeholder"
		return s
	elseif tag == "RECT" then
		return Rect.new(d[2], d[3], d[4], d[5])
	elseif tag == "V2" then
		return Vector2.new(d[2], d[3])
	elseif tag == "PP" then
		return PhysicalProperties.new(d[2], d[3], d[4], d[5], d[6])
	elseif tag == "FF" then
		return FontFace.new(d[2], d[3], d[4])
	elseif tag == "NS" then
		local keys = {}
		for i, k in ipairs(d[2]) do
			keys[i] = NumberSequenceKeypoint.new(k[1], k[2], k[3])
		end
		return NumberSequence.new(keys)
	elseif tag == "CS" then
		local keys = {}
		for i, k in ipairs(d[2]) do
			keys[i] = ColorSequenceKeypoint.new(k[1], Color3.new(k[2], k[3], k[4]))
		end
		return ColorSequence.new(keys)
	elseif tag == "RAY" then
		return Ray.new(Vector3.new(d[2], d[3], d[4]), Vector3.new(d[5], d[6], d[7]))
	elseif tag == "R3" then
		return Region3.new(Vector3.new(d[2], d[3], d[4]), Vector3.new(d[5], d[6], d[7]))
	elseif tag == "V3I" then
		return Vector3int16.new(d[2], d[3], d[4])
	elseif tag == "V2I" then
		return Vector2int16.new(d[2], d[3])
	elseif tag == "UD" then
		return UDim.new(d[2], d[3])
	end
	return d
end

local PROPS = {
	"CFrame","Position","Orientation","Size","Transparency",
	"Color","BrickColor","Material","Anchored","CanCollide",
	"Shape","Value","Text","Image",
	"BackgroundColor3","BackgroundTransparency","TextColor3",
	"Reflectance","Texture","MeshId","TextureID","Scale",
	"Offset","VertexColor","MeshType","Material",
	"Locked","CastShadow","CanQuery","CanTouch",
	"MaxForce","MaxTorque","Velocity","RotVelocity",
	"Massless","CustomPhysicalProperties","Density",
	"Friction","Elasticity","FrictionWeight","ElasticityWeight",
	"SoundId","Volume","Pitch","Looped","Playing",
	"TimePosition","PlaybackSpeed","EmitterSize","Rate",
	"Lifetime","SpreadAngle","Rotation","Speed","Acceleration",
	"Drag","VelocityInheritance","LightColor","Brightness",
	"Range","Shadows","Angle","Face","Faces","Style",
	"TextSize","Font","TextTransparency","TextStrokeTransparency",
	"TextStrokeColor3","TextWrapped","TextScaled","RichText",
	"BorderSizePixel","BorderColor3","BackgroundTransparency",
	"SizeConstraint","MaxVisibleGraphemes","LineHeight",
	"TextXAlignment","TextYAlignment","TextTruncate","FontFace",
	"AnchorPoint","Position","Rotation","Visible","Active",
	"AutoButtonColor","Modal","Selected","Selectable",
	"SelectionImageObject","ImageTransparency","ImageColor3",
	"ScaleType","SliceCenter","TileSize","ResampleMode",
	"ImageRectOffset","ImageRectSize","ImageContent",
	"ImageColor3","ImageTransparency","Scale","Offset",
	"Size","Color","Transparency","ZIndex","LayoutOrder",
	"ClipsDescendants","FillDirection","HorizontalAlignment",
	"VerticalAlignment","Padding","SortOrder","AutomaticSize",
}

local serCnt = 0

local function serInst(inst)
	if isOwned(inst) then return nil end
	serCnt = serCnt + 1
	if serCnt % YIELD_EVERY == 0 then task.wait() end
	local data = {Class=inst.ClassName, Name=inst.Name, Properties={}, Children={}}
	for _, pn in ipairs(PROPS) do
		local ok, val = pcall(function() return inst[pn] end)
		if ok and val ~= nil then
			local s = ser(val)
			if s ~= nil then data.Properties[pn] = s end
		end
	end
	if inst:IsA("Instance") and inst:GetAttributes() ~= {} then
		data.Attributes = {}
		for an, av in pairs(inst:GetAttributes()) do
			local s = ser(av)
			if s ~= nil then data.Attributes[an] = s end
		end
	end
	for _, c in ipairs(inst:GetChildren()) do
		if not isOwned(c) then
			local cd = serInst(c)
			if cd then table.insert(data.Children, cd) end
		end
	end
	return data
end

local desCnt = 0

local function creInst(data, parent)
	desCnt = desCnt + 1
	if desCnt % YIELD_EVERY == 0 then task.wait() end
	local ok, inst = pcall(function() return Instance.new(data.Class) end)
	if not ok then inst = Instance.new("Folder") end
	inst.Name = data.Name
	inst.Parent = parent
	for pn, pv in pairs(data.Properties) do
		local d = des(pv)
		if d ~= nil then pcall(function() inst[pn] = d end) end
	end
	if data.Attributes then
		for an, av in pairs(data.Attributes) do
			local d = des(av)
			if d ~= nil then pcall(function() inst:SetAttribute(an, d) end) end
		end
	end
	for _, cd in ipairs(data.Children) do
		creInst(cd, inst)
	end
	return inst
end

local function saveWS()
	local root = {}
	for _, o in ipairs(workspace:GetChildren()) do
		if not isOwned(o) then
			local s = serInst(o)
			if s then table.insert(root, s) end
		end
	end
	local ok, json = pcall(http.JSONEncode, http, root)
	if not ok then
		warn("JSONEncode pizda.")
		root = {}
		for _, o in ipairs(workspace:GetChildren()) do
			if not isOwned(o) and not o:IsA("Model") and not o:IsA("Folder") then
				local s = serInst(o)
				if s then table.insert(root, s) end
			end
		end
		ok, json = pcall(http.JSONEncode, http, root)
		if not ok then error("Serialize pizda") end
	end
	return json
end

local function loadWS(json)
	local ok, data = pcall(function() return http:JSONDecode(json) end)
	if not ok then error("invalid json") end

	local oldGravity = workspace.Gravity
	workspace.Gravity = 0

	for _, o in ipairs(workspace:GetChildren()) do
		if o ~= workspace.Terrain and not isOwned(o) then
			o:Destroy()
			task.wait()
		end
	end

	desCnt = 0
	for _, d in ipairs(data) do
		creInst(d, workspace)
	end

	workspace.Gravity = oldGravity
end

local queue = {}
local sending = false
local lastSend = 0
local MIN_INTERVAL = 1

local function sendWebhook(text)
	if WEBHOOK_URL == "" then warn("no webhook") return end
	table.insert(queue, text)
	if not sending then
		sending = true
		task.spawn(function()
			while #queue > 0 do
				local chunk = table.remove(queue, 1)
				local now = os.clock()
				local wait = MIN_INTERVAL - (now - lastSend)
				if wait > 0 then task.wait(wait) end
				lastSend = os.clock()
				task.wait()
				local payload = {
					content = "Workspace Save",
					username = "TNR.exe",
					embeds = {{
						title = "Saved Workspace Chunk",
						description = "```json\n" .. chunk .. "\n```",
						color = 0xFFFFFF,
						footer = {text = "TNR.exe by Bond_pley"}
					}}
				}
				local jsonData = http:JSONEncode(payload)
				local ok, err = pcall(function()
					http:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
				end)
				if not ok then
					warn("webhook error:", err)
					task.wait(2)
					pcall(function() http:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson) end)
				end
			end
			sending = false
		end)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "TNRexe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = lp:WaitForChild("PlayerGui")

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
end

local function stroke(obj, t, c)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = c or BORDER
	s.Parent = obj
end

local function padding(obj, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingRight = UDim.new(0, r)
	p.PaddingBottom = UDim.new(0, b)
	p.PaddingLeft = UDim.new(0, l)
	p.Parent = obj
end

local function tween(obj, props, time, style, dir)
	style = style or Enum.EasingStyle.Sine
	dir = dir or Enum.EasingDirection.Out
	return tw:Create(obj, TweenInfo.new(time or 0.18, style, dir), props)
end

local frame = Instance.new("Frame")
frame.Parent = gui
frame.AnchorPoint = Vector2.new(0,0)
frame.Position = UDim2.new(0,20,0,-700)
frame.Size = UDim2.new(0,700,0,600)
frame.BackgroundColor3 = PANEL
frame.ClipsDescendants = true
corner(frame,10)
stroke(frame,1)

local header = Instance.new("Frame")
header.Parent = frame
header.Size = UDim2.new(1,0,0,56)
header.BackgroundColor3 = BG
corner(header,10)

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(1,-24,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.ArialBold
title.TextSize = 20
title.TextColor3 = TXT
title.Text = "TNR.exe | WorkspaceSerializer"
title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel")
sub.Parent = header
sub.AnchorPoint = Vector2.new(1,0)
sub.Position = UDim2.new(1,-12,0,0)
sub.Size = UDim2.new(0.4,0,1,0)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.ArialBold
sub.TextSize = 12
sub.TextColor3 = MUTED
sub.Text = "Tooling & Node Runtime WorkspaceSerializer"
sub.TextXAlignment = Enum.TextXAlignment.Right

local drag = false
local dragStart = nil
local frameStart = nil

header.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = true
		dragStart = inp.Position
		frameStart = frame.Position
		inp.Changed:Connect(function()
			if inp.UserInputState == Enum.UserInputState.End then drag = false end
		end)
	end
end)

header.InputChanged:Connect(function(inp)
	if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = inp.Position - dragStart
		local newPos = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
		tween(frame, {Position = newPos}, 0.1):Play()
	end
end)

local tabs = Instance.new("Frame")
tabs.Parent = frame
tabs.Position = UDim2.new(0,0,0,64)
tabs.Size = UDim2.new(1,0,0,44)
tabs.BackgroundTransparency = 1

local function tabBtn(text, pos, size)
	local b = Instance.new("TextButton")
	b.Parent = tabs
	b.Size = size or UDim2.new(0.5,-10,1,-6)
	b.Position = pos
	b.BackgroundColor3 = BG
	b.TextColor3 = MUTED
	b.Font = Enum.Font.ArialBold
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = false
	corner(b,8)
	stroke(b,1)
	b.MouseEnter:Connect(function()
		playSnd(lp.PlayerGui, SND_HOVER)
		tween(b, {BackgroundColor3 = PANEL, TextColor3 = TXT}, 0.12):Play()
	end)
	b.MouseLeave:Connect(function()
		tween(b, {BackgroundColor3 = BG, TextColor3 = MUTED}, 0.12):Play()
	end)
	return b
end

	local function saveToFile()
		local text = fullJson
		if text == "" then
			warn("Nothing to save!")
			return
		end
		local success, err = pcall(function()
			writefile("TNR_WorkspaceSerializer_"..game.GameId..".json", text)
		end)
		if success then
			print("File saved to Desktop!")
		else
			warn("Save failed: " .. tostring(err))
		end
	end

local tabChunks = tabBtn("Chunks", UDim2.new(0,6,0,3))
local tabFull = tabBtn("Full JSON", UDim2.new(0.5,6,0,3))

local content = Instance.new("Frame")
content.Parent = frame
content.Position = UDim2.new(0,12,0,116)
content.Size = UDim2.new(1,-24,1,-170)
content.BackgroundTransparency = 1
content.ClipsDescendants = true

local left = Instance.new("Frame")
left.Parent = content
left.Position = UDim2.new(0,0,0,0)
left.Size = UDim2.new(0.46,0,1,0)
left.BackgroundTransparency = 1

local right = Instance.new("Frame")
right.Parent = content
right.Position = UDim2.new(0.48,0,0,0)
right.Size = UDim2.new(0.52,0,1,0)
right.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = left
scroll.Size = UDim2.new(1,0,1,0)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.Padding = UDim.new(0,10)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local fullView = Instance.new("Frame")
fullView.Parent = right
fullView.Size = UDim2.new(1,0,1,0)
fullView.BackgroundColor3 = BG
fullView.ClipsDescendants = true
corner(fullView,8)
stroke(fullView,1)
padding(fullView,8,8,8,8)

local fullBox = Instance.new("TextBox")
fullBox.Parent = fullView
fullBox.Size = UDim2.new(1,-12,1,-12)
fullBox.Position = UDim2.new(0,6,0,6)
fullBox.TextXAlignment = Enum.TextXAlignment.Left
fullBox.TextYAlignment = Enum.TextYAlignment.Top
fullBox.ClearTextOnFocus = false
fullBox.BackgroundTransparency = 1
fullBox.TextColor3 = TXT
fullBox.Font = Enum.Font.Code
fullBox.TextSize = 14
fullBox.MultiLine = true
fullBox.TextWrapped = true
fullBox.Text = "-- JSON will appear here after saving --"

local btnRow = Instance.new("Frame")
btnRow.Parent = frame
btnRow.Size = UDim2.new(1,-24,0,48)
btnRow.Position = UDim2.new(0,12,1,-72)
btnRow.BackgroundTransparency = 1

local function actBtn(text, pos, size, col)
	local b = Instance.new("TextButton")
	b.Parent = btnRow
	b.Size = size or UDim2.new(0.33,-8,1,0)
	b.Position = pos
	b.BackgroundColor3 = col or ACC
	b.TextColor3 = BG
	b.Font = Enum.Font.ArialBold
	b.Text = text
	b.TextSize = 14
	b.AutoButtonColor = false
	corner(b,8)
	stroke(b,0.5)
	b.MouseEnter:Connect(function()
		playSnd(lp.PlayerGui, SND_HOVER)
		tween(b, {BackgroundColor3 = ACC2}, 0.12):Play()
	end)
	b.MouseLeave:Connect(function()
		tween(b, {BackgroundColor3 = col or ACC}, 0.12):Play()
	end)
	return b
end

local saveBtn = actBtn("SAVE", UDim2.new(0,0,0,0), UDim2.new(0.25,-6,1,0))
local loadChunks = actBtn("Load Chunks", UDim2.new(0.25,6,0,0), UDim2.new(0.25,-6,1,0))
local loadFull = actBtn("Load Full", UDim2.new(0.5,6,0,0), UDim2.new(0.25,-6,1,0))
local copyBtn = actBtn("Copy", UDim2.new(0.75,6,0,0), UDim2.new(0.25,-6,1,0), Color3.fromRGB(180,180,180))

local toast = Instance.new("TextLabel")
toast.Parent = frame
toast.AnchorPoint = Vector2.new(0,1)
toast.Position = UDim2.new(0,12,1,-8)
toast.Size = UDim2.new(0.5,0,0,28)
toast.BackgroundTransparency = 1
toast.TextColor3 = MUTED
toast.Font = Enum.Font.ArialBold
toast.TextSize = 12
toast.Text = ""
toast.TextTransparency = 1

local overlay = Instance.new("Frame")
overlay.Parent = frame
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 10

local shade = Instance.new("Frame")
shade.Parent = overlay
shade.Size = UDim2.new(1,0,1,0)
shade.BackgroundTransparency = 0.6
shade.BackgroundColor3 = Color3.new(0,0,0)
shade.ZIndex = 10

local statusBox = Instance.new("Frame")
statusBox.Parent = overlay
statusBox.Size = UDim2.new(0,320,0,120)
statusBox.Position = UDim2.new(0.5,-160,0.5,-60)
statusBox.BackgroundColor3 = BG
corner(statusBox,8)
stroke(statusBox,1)
statusBox.ZIndex = 11

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusBox
statusLabel.Size = UDim2.new(1,-20,0,40)
statusLabel.Position = UDim2.new(0,10,0,10)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.ArialBold
statusLabel.TextSize = 16
statusLabel.TextColor3 = TXT
statusLabel.Text = "Working..."
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local progBg = Instance.new("Frame")
progBg.Parent = statusBox
progBg.Size = UDim2.new(1,-20,0,18)
progBg.Position = UDim2.new(0,10,0,64)
progBg.BackgroundColor3 = Color3.fromRGB(24,24,24)
corner(progBg,9)

local progFill = Instance.new("Frame")
progFill.Parent = progBg
progFill.Size = UDim2.new(0,0,1,0)
progFill.Position = UDim2.new(0,0,0,0)
corner(progFill,9)
progFill.BackgroundColor3 = ACC

local function showOverlay(text)
	overlay.Visible = true
	statusLabel.Text = text or "Working..."
	progFill.Size = UDim2.new(0,0,1,0)
	statusBox.Position = UDim2.new(0.5,-160,0.5,-200)
	tween(statusBox, {Position = UDim2.new(0.5,-160,0.5,-60)}, 0.35, Enum.EasingStyle.Back):Play()
end

local function hideOverlay()
	tween(statusBox, {Position = UDim2.new(0.5,-160,0.5,60)}, 0.25):Play()
	task.delay(0.25, function() overlay.Visible = false end)
end

local function setProg(frac)
	frac = math.clamp(frac,0,1)
	tween(progFill, {Size = UDim2.new(frac,0,1,0)}, 0.1):Play()
end

local chunksData = {}
local chunkFrames = {}
local fullJson = ""
local fullTrunc = false

local function clearChunks()
	for _, f in ipairs(chunkFrames) do f:Destroy() end
	chunkFrames = {}
end

local function addChunkUI(text, idx)
	local card = Instance.new("Frame")
	card.Parent = scroll
	card.Size = UDim2.new(1,-8,0,120)
	card.BackgroundColor3 = BG
	card.ClipsDescendants = true
	corner(card,8)
	stroke(card,1)
	padding(card,8,8,8,8)
	card.LayoutOrder = idx or 1

	local bar = Instance.new("Frame")
	bar.Parent = card
	bar.Size = UDim2.new(1,0,0,6)
	bar.Position = UDim2.new(0,0,0,0)
	bar.BackgroundColor3 = ACC
	corner(bar,6)

	local box = Instance.new("TextBox")
	box.Parent = card
	box.Size = UDim2.new(1,-12,1,-12)
	box.Position = UDim2.new(0,6,0,6)
	box.BackgroundTransparency = 1
	box.TextColor3 = TXT
	box.Font = Enum.Font.Code
	box.TextSize = 13
	box.Text = text
	box.ClearTextOnFocus = false
	box.TextWrapped = true
	box.MultiLine = true
	box.TextEditable = false

	local expanded = false
	local collapsedH = 120
	local expandedH = 280

	card.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			expanded = not expanded
			local target = expanded and UDim2.new(1,-8,0,expandedH) or UDim2.new(1,-8,0,collapsedH)
			tween(card, {Size = target}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
		end
	end)

	card.MouseEnter:Connect(function()
		tween(card, {BackgroundColor3 = PANEL}, 0.12):Play()
	end)
	card.MouseLeave:Connect(function()
		if not expanded then tween(card, {BackgroundColor3 = BG}, 0.12):Play() end
	end)

	table.insert(chunkFrames, card)
	return card
end

local function updateChunksUI(json)
	clearChunks()
	chunksData = {}
	if #json <= MAX_CHUNK then
		chunksData = {json}
	else
		local start = 1
		while start <= #json do
			local e = math.min(start + MAX_CHUNK - 1, #json)
			table.insert(chunksData, json:sub(start, e))
			start = e + 1
			task.wait()
		end
	end
	for i, c in ipairs(chunksData) do
		addChunkUI(c, i)
	end
end

local function showChunks()
	tabChunks.BackgroundColor3 = PANEL
	tabChunks.TextColor3 = TXT
	tabFull.BackgroundColor3 = BG
	tabFull.TextColor3 = MUTED
	left.Visible = true
	right.Visible = true
end

local function showFull()
	tabFull.BackgroundColor3 = PANEL
	tabFull.TextColor3 = TXT
	tabChunks.BackgroundColor3 = BG
	tabChunks.TextColor3 = MUTED
	left.Visible = true
	right.Visible = true
end

tabChunks.MouseButton1Click:Connect(showChunks)
tabFull.MouseButton1Click:Connect(showFull)

saveBtn.MouseButton1Click:Connect(function()
	showOverlay("Saving workspace...")
	task.spawn(function()
		serCnt = 0
		local success, json = pcall(saveWS)
		if not success then
			hideOverlay()
			warn("Save failed:", json)
			toast.Text = "Save failed: " .. tostring(json)
			toast.TextTransparency = 0
			task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
			return
		end

		fullJson = json
		fullTrunc = (#json > PREVIEW_MAX)

		if fullTrunc then
			fullBox.Text = json:sub(1, PREVIEW_MAX) .. "\n...[truncated, use Copy to get full JSON]"
			saveToFile()
		else
			fullBox.Text = json
		end

		updateChunksUI(json)
		sendWebhook(json)

		hideOverlay()
		playSnd(lp.PlayerGui, SND_SUC)
		toast.Text = "Workspace saved successfully!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
	end)
end)

loadChunks.MouseButton1Click:Connect(function()
	local full = ""
	for _, f in ipairs(chunkFrames) do
		local box = f:FindFirstChildOfClass("TextBox")
		if box then full = full .. box.Text end
	end
	if full == "" then
		toast.Text = "No chunks to load!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
		return
	end
	showOverlay("Loading from chunks...")
	task.spawn(function()
		desCnt = 0
		local ok, err = pcall(loadWS, full)
		if not ok then
			hideOverlay()
			warn("Load failed:", err)
			toast.Text = "Load failed: " .. tostring(err)
			toast.TextTransparency = 0
			task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
			return
		end
		hideOverlay()
		playSnd(lp.PlayerGui, SND_SUC)
		toast.Text = "Workspace loaded successfully!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
	end)
end)

loadFull.MouseButton1Click:Connect(function()
	local json
	if fullJson ~= "" then json = fullJson else json = fullBox.Text end
	if json == "" or json:sub(1,1) ~= "[" then
		toast.Text = "Invalid JSON in Full View!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
		return
	end
	showOverlay("Loading from full JSON...")
	task.spawn(function()
		desCnt = 0
		local ok, err = pcall(loadWS, json)
		if not ok then
			hideOverlay()
			warn("Load failed:", err)
			toast.Text = "Load failed: " .. tostring(err)
			toast.TextTransparency = 0
			task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
			return
		end
		hideOverlay()
		playSnd(lp.PlayerGui, SND_SUC)
		toast.Text = "Workspace loaded successfully!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
	end)
end)

copyBtn.MouseButton1Click:Connect(function()
	local text = fullJson ~= "" and fullJson or fullBox.Text
	if text == "" then
		toast.Text = "Nothing to copy!"
		toast.TextTransparency = 0
		task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
		return
	end
	local success = false
	local errMsg = ""
	if setclipboard then
		local ok, err = pcall(setclipboard, text)
		if ok then success = true else errMsg = tostring(err) end
	else
		_G.TNR_clipboard = text
		success = true
		errMsg = "Copied to _G.TNR_clipboard"
	end
	if success then
		toast.Text = "Copied to clipboard!"
	else
		toast.Text = "Copy failed: " .. errMsg
	end
	toast.TextTransparency = 0
	task.delay(2, function() tween(toast, {TextTransparency = 1}, 0.3):Play() end)
end)

uis.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.S and inp.UserInputType == Enum.UserInputType.Keyboard then
		if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.RightControl) then
			saveBtn:Invoke()
		end
	end
end)

local autoSave = false
local lastAuto = os.clock()

run.Heartbeat:Connect(function()
	if autoSave and os.clock() - lastAuto > AUTO_SAVE then
		lastAuto = os.clock()
		saveBtn:Invoke()
	end
end)

showChunks()
fullBox.Text = "-- JSON will appear here after saving --"

frame.Position = UDim2.new(0,20,0,-700)
tween(frame, {Position = UDim2.new(0,20,0,40)}, 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
playSnd(lp.PlayerGui, SND_SUC)

print("TNR.exe loaded.")

end

