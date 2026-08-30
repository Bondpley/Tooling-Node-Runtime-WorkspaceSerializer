--==========================================================================--
--                Tooling Node Runtime WorkspaceSerializer                  --
------------------------------------------------------------------------------
--   https://github.com/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer   --
--                               By Bondpley                                --
--==========================================================================--

return(function(webhookUrl)
    local httpService = game:GetService("HttpService")
    local playersService = game:GetService("Players")
    local tweenService = game:GetService("TweenService")
    local runService = game:GetService("RunService")
    local inputService = game:GetService("UserInputService")
    local localPlayer = playersService.LocalPlayer
    if not localPlayer then return end
    
    local maxChunkSize = 180000
    local autoSaveInterval = 300
    local yieldEvery = 9999
    local previewMax = 100000
    
    local function sanitizeNumber(value)
        if type(value) == "number" then
            if value ~= value or value == math.huge or value == -math.huge then return 0 end
        end
        return value
    end
    
    local function encodeValue(value)
        local valueType = typeof(value)
        if valueType == "Vector3" then
            return {"V3", sanitizeNumber(value.X), sanitizeNumber(value.Y), sanitizeNumber(value.Z)}
        elseif valueType == "Color3" then
            return {"C3", sanitizeNumber(value.R), sanitizeNumber(value.G), sanitizeNumber(value.B)}
        elseif valueType == "UDim2" then
            return {"UD2", sanitizeNumber(value.X.Scale), sanitizeNumber(value.X.Offset), sanitizeNumber(value.Y.Scale), sanitizeNumber(value.Y.Offset)}
        elseif valueType == "BrickColor" then
            return {"BC", sanitizeNumber(value.Number)}
        elseif valueType == "NumberRange" then
            return {"NR", sanitizeNumber(value.Min), sanitizeNumber(value.Max)}
        elseif valueType == "EnumItem" then
            return {"EN", tostring(value.EnumType), value.Name}
        elseif valueType == "CFrame" then
            local position, lookVector, upVector = value.Position, value.LookVector, value.UpVector
            return {"CF", sanitizeNumber(position.X), sanitizeNumber(position.Y), sanitizeNumber(position.Z), sanitizeNumber(lookVector.X), sanitizeNumber(lookVector.Y), sanitizeNumber(lookVector.Z), sanitizeNumber(upVector.X), sanitizeNumber(upVector.Y), sanitizeNumber(upVector.Z)}
        elseif valueType == "Instance" then
            if value:IsA("Script") or value:IsA("LocalScript") or value:IsA("ModuleScript") then
                return {"SCRIPT", value.Name}
            end
            return nil
        elseif valueType == "Rect" then
            return {"RECT", sanitizeNumber(value.Min.X), sanitizeNumber(value.Min.Y), sanitizeNumber(value.Max.X), sanitizeNumber(value.Max.Y)}
        elseif valueType == "Vector2" then
            return {"V2", sanitizeNumber(value.X), sanitizeNumber(value.Y)}
        elseif valueType == "PhysicalProperties" then
            return {"PP", sanitizeNumber(value.Density), sanitizeNumber(value.Friction), sanitizeNumber(value.Elasticity), sanitizeNumber(value.FrictionWeight), sanitizeNumber(value.ElasticityWeight)}
        elseif valueType == "FontFace" then
            return {"FF", value.Family, value.Weight, value.Style}
        elseif valueType == "NumberSequence" then
            local keypoints = {}
            for index, keypoint in ipairs(value.Keypoints) do
                keypoints[index] = {sanitizeNumber(keypoint.Time), sanitizeNumber(keypoint.Value), sanitizeNumber(keypoint.Envelope)}
            end
            return {"NS", keypoints}
        elseif valueType == "ColorSequence" then
            local keypoints = {}
            for index, keypoint in ipairs(value.Keypoints) do
                keypoints[index] = {sanitizeNumber(keypoint.Time), sanitizeNumber(keypoint.Value.R), sanitizeNumber(keypoint.Value.G), sanitizeNumber(keypoint.Value.B)}
            end
            return {"CS", keypoints}
        elseif valueType == "Ray" then
            return {"RAY", sanitizeNumber(value.Origin.X), sanitizeNumber(value.Origin.Y), sanitizeNumber(value.Origin.Z), sanitizeNumber(value.Direction.X), sanitizeNumber(value.Direction.Y), sanitizeNumber(value.Direction.Z)}
        elseif valueType == "Region3" then
            return {"R3", sanitizeNumber(value.Min.X), sanitizeNumber(value.Min.Y), sanitizeNumber(value.Min.Z), sanitizeNumber(value.Max.X), sanitizeNumber(value.Max.Y), sanitizeNumber(value.Max.Z)}
        elseif valueType == "Vector3int16" then
            return {"V3I", sanitizeNumber(value.X), sanitizeNumber(value.Y), sanitizeNumber(value.Z)}
        elseif valueType == "Vector2int16" then
            return {"V2I", sanitizeNumber(value.X), sanitizeNumber(value.Y)}
        elseif valueType == "UDim" then
            return {"UD", sanitizeNumber(value.Scale), sanitizeNumber(value.Offset)}
        elseif valueType == "string" then
            return value
        elseif valueType == "number" then
            return sanitizeNumber(value)
        elseif valueType == "boolean" then
            return value
        else
            return nil
        end
    end
    
    local function decodeValue(data)
        if type(data) ~= "table" then return data end
        local tag = data[1]
        if tag == "V3" then
            return Vector3.new(data[2], data[3], data[4])
        elseif tag == "C3" then
            return Color3.new(data[2], data[3], data[4])
        elseif tag == "UD2" then
            return UDim2.new(data[2], data[3], data[4], data[5])
        elseif tag == "BC" then
            return BrickColor.new(data[2])
        elseif tag == "NR" then
            return NumberRange.new(data[2], data[3])
        elseif tag == "EN" then
            local enum = Enum[data[2]]
            if enum then return enum[data[3]] end
            return nil
        elseif tag == "CF" then
            local position = Vector3.new(data[2], data[3], data[4])
            local lookVector = Vector3.new(data[5], data[6], data[7])
            local upVector = Vector3.new(data[8], data[9], data[10])
            local success, cframe = pcall(function()
                return CFrame.lookAt(position, position + lookVector, upVector)
            end)
            return success and cframe or CFrame.new(position)
        elseif tag == "SCRIPT" then
            local script = Instance.new("Script")
            script.Name = data[2]
            script.Source = " "
            return script
        elseif tag == "RECT" then
            return Rect.new(data[2], data[3], data[4], data[5])
        elseif tag == "V2" then
            return Vector2.new(data[2], data[3])
        elseif tag == "PP" then
            return PhysicalProperties.new(data[2], data[3], data[4], data[5], data[6])
        elseif tag == "FF" then
            return FontFace.new(data[2], data[3], data[4])
        elseif tag == "NS" then
            local keypoints = {}
            for index, keypoint in ipairs(data[2]) do
                keypoints[index] = NumberSequenceKeypoint.new(keypoint[1], keypoint[2], keypoint[3])
            end
            return NumberSequence.new(keypoints)
        elseif tag == "CS" then
            local keypoints = {}
            for index, keypoint in ipairs(data[2]) do
                keypoints[index] = ColorSequenceKeypoint.new(keypoint[1], Color3.new(keypoint[2], keypoint[3], keypoint[4]))
            end
            return ColorSequence.new(keypoints)
        elseif tag == "RAY" then
            return Ray.new(Vector3.new(data[2], data[3], data[4]), Vector3.new(data[5], data[6], data[7]))
        elseif tag == "R3" then
            return Region3.new(Vector3.new(data[2], data[3], data[4]), Vector3.new(data[5], data[6], data[7]))
        elseif tag == "V3I" then
            return Vector3int16.new(data[2], data[3], data[4])
        elseif tag == "V2I" then
            return Vector2int16.new(data[2], data[3])
        elseif tag == "UD" then
            return UDim.new(data[2], data[3])
        end
        return data
    end
    
    local trackedProperties = {
        "CFrame", "Position", "Orientation", "Size", "Transparency", "Color", "BrickColor", "Material",
        "Anchored", "CanCollide", "Shape", "Value", "Text", "Image", "BackgroundColor3",
        "BackgroundTransparency", "TextColor3", "Reflectance", "Texture", "MeshId", "TextureID",
        "Scale", "Offset", "VertexColor", "MeshType", "Locked", "CastShadow", "CanQuery", "CanTouch",
        "MaxForce", "MaxTorque", "Velocity", "RotVelocity", "Massless", "CustomPhysicalProperties",
        "Density", "Friction", "Elasticity", "FrictionWeight", "ElasticityWeight", "SoundId", "Volume",
        "Pitch", "Looped", "Playing", "TimePosition", "PlaybackSpeed", "EmitterSize", "Rate",
        "Lifetime", "SpreadAngle", "Rotation", "Speed", "Acceleration", "Drag", "VelocityInheritance",
        "LightColor", "Brightness", "Range", "Shadows", "Angle", "Face", "Faces", "Style", "TextSize",
        "Font", "TextTransparency", "TextStrokeTransparency", "TextStrokeColor3", "TextWrapped",
        "TextScaled", "RichText", "BorderSizePixel", "BorderColor3", "SizeConstraint",
        "MaxVisibleGraphemes", "LineHeight", "TextXAlignment", "TextYAlignment", "TextTruncate",
        "FontFace", "AnchorPoint", "Rotation", "Visible", "Active", "AutoButtonColor", "Modal",
        "Selected", "Selectable", "SelectionImageObject", "ImageTransparency", "ImageColor3",
        "ScaleType", "SliceCenter", "TileSize", "ResampleMode", "ImageRectOffset", "ImageRectSize",
        "ImageContent", "ZIndex", "LayoutOrder", "ClipsDescendants", "FillDirection",
        "HorizontalAlignment", "VerticalAlignment", "Padding", "SortOrder", "AutomaticSize",
        "MeshId", "TextureID", "VertexColor", "RenderFidelity", "CollisionFidelity", "GlobalWind"
    }
    
    local encodeCounter = 0
    local function encodeInstance(instance)
        encodeCounter = encodeCounter + 1
        if encodeCounter % yieldEvery == 0 then task.wait() end
        
        local data = {
            Class = instance.ClassName,
            Name = instance.Name,
            Properties = {},
            Children = {}
        }
        
        for _, propertyName in ipairs(trackedProperties) do
            local success, value = pcall(function()
                return instance[propertyName]
            end)
            if success and value ~= nil then
                local encoded = encodeValue(value)
                if encoded ~= nil then
                    data.Properties[propertyName] = encoded
                end
            end
        end
        
        if instance:IsA("MeshPart") or instance:IsA("SpecialMesh") or instance:IsA("BlockMesh") or instance:IsA("CylinderMesh") then
            if instance:IsA("MeshPart") then
                local meshId = pcall(function() return instance.MeshId end) and instance.MeshId or ""
                local textureId = pcall(function() return instance.TextureID end) and instance.TextureID or ""
                if meshId ~= "" then
                    data.Properties.MeshId = meshId
                end
                if textureId ~= "" then
                    data.Properties.TextureID = textureId
                end
                local vertexColor = pcall(function() return instance.VertexColor end) and instance.VertexColor or nil
                if vertexColor then
                    data.Properties.VertexColor = encodeValue(vertexColor)
                end
            end
        end
        
        if instance:IsA("Part") or instance:IsA("MeshPart") then
            local materialVariant = pcall(function() return instance.MaterialVariant end) and instance.MaterialVariant or nil
            if materialVariant then
                data.Properties.MaterialVariant = encodeValue(materialVariant)
            end
        end
        
        if instance:IsA("Decal") or instance:IsA("Texture") then
            local texture = pcall(function() return instance.Texture end) and instance.Texture or ""
            if texture ~= "" then
                data.Properties.Texture = texture
            end
            local face = pcall(function() return instance.Face end) and instance.Face or nil
            if face then
                data.Properties.Face = encodeValue(face)
            end
        end
        
        if instance:IsA("Sound") then
            local soundId = pcall(function() return instance.SoundId end) and instance.SoundId or ""
            if soundId ~= "" then
                data.Properties.SoundId = soundId
            end
        end
        
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            local image = pcall(function() return instance.Image end) and instance.Image or ""
            if image ~= "" then
                data.Properties.Image = image
            end
            local imageColor3 = pcall(function() return instance.ImageColor3 end) and instance.ImageColor3 or nil
            if imageColor3 then
                data.Properties.ImageColor3 = encodeValue(imageColor3)
            end
        end
        
        if instance:IsA("Frame") or instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            local backgroundImage = pcall(function() return instance.BackgroundImage end) and instance.BackgroundImage or ""
            if backgroundImage ~= "" then
                data.Properties.BackgroundImage = backgroundImage
            end
            local backgroundImageColor3 = pcall(function() return instance.BackgroundImageColor3 end) and instance.BackgroundImageColor3 or nil
            if backgroundImageColor3 then
                data.Properties.BackgroundImageColor3 = encodeValue(backgroundImageColor3)
            end
        end
        
        if instance:IsA("Attachment") then
            local orientation = pcall(function() return instance.Orientation end) and instance.Orientation or nil
            if orientation then
                data.Properties.Orientation = encodeValue(orientation)
            end
            local position = pcall(function() return instance.Position end) and instance.Position or nil
            if position then
                data.Properties.Position = encodeValue(position)
            end
        end
        
        if instance:IsA("Beam") or instance:IsA("Trail") then
            local color = pcall(function() return instance.Color end) and instance.Color or nil
            if color then
                data.Properties.Color = encodeValue(color)
            end
            local texture = pcall(function() return instance.Texture end) and instance.Texture or ""
            if texture ~= "" then
                data.Properties.Texture = texture
            end
            local textureMode = pcall(function() return instance.TextureMode end) and instance.TextureMode or nil
            if textureMode then
                data.Properties.TextureMode = encodeValue(textureMode)
            end
        end
        
        if instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("SelectionBox") then
            local adornee = pcall(function() return instance.Adornee end) and instance.Adornee or nil
            if adornee then
                data.Properties.Adornee = encodeValue(adornee)
            end
        end
        
        if instance:IsA("BasePart") then
            local color = pcall(function() return instance.Color end) and instance.Color or nil
            if color then
                data.Properties.Color = encodeValue(color)
            end
            local material = pcall(function() return instance.Material end) and instance.Material or nil
            if material then
                data.Properties.Material = encodeValue(material)
            end
            local transparency = pcall(function() return instance.Transparency end) and instance.Transparency or nil
            if transparency then
                data.Properties.Transparency = transparency
            end
            local reflectance = pcall(function() return instance.Reflectance end) and instance.Reflectance or nil
            if reflectance then
                data.Properties.Reflectance = reflectance
            end
            local size = pcall(function() return instance.Size end) and instance.Size or nil
            if size then
                data.Properties.Size = encodeValue(size)
            end
        end
        
        if instance:GetAttributes() and next(instance:GetAttributes()) then
            data.Attributes = {}
            for attributeName, attributeValue in pairs(instance:GetAttributes()) do
                local encoded = encodeValue(attributeValue)
                if encoded ~= nil then
                    data.Attributes[attributeName] = encoded
                end
            end
        end
        
        for _, child in ipairs(instance:GetChildren()) do
            local childData = encodeInstance(child)
            if childData then
                table.insert(data.Children, childData)
            end
        end
        
        return data
    end
    
    local decodeCounter = 0
    local function createInstance(data, parent)
        decodeCounter = decodeCounter + 1
        if decodeCounter % yieldEvery == 0 then task.wait() end
        
        local success, instance = pcall(function()
            return Instance.new(data.Class)
        end)
        if not success then
            instance = Instance.new("Folder")
        end
        
        instance.Name = data.Name
        instance.Parent = parent
        
        for propertyName, propertyValue in pairs(data.Properties) do
            local decoded = decodeValue(propertyValue)
            if decoded ~= nil then
                pcall(function()
                    instance[propertyName] = decoded
                end)
            end
        end
        
        if data.Attributes then
            for attributeName, attributeValue in pairs(data.Attributes) do
                local decoded = decodeValue(attributeValue)
                if decoded ~= nil then
                    pcall(function()
                        instance:SetAttribute(attributeName, decoded)
                    end)
                end
            end
        end
        
        for _, childData in ipairs(data.Children) do
            createInstance(childData, instance)
        end
        
        return instance
    end
    
    local function saveWorkspace()
        local root = {}
        for _, object in ipairs(workspace:GetChildren()) do
            local encoded = encodeInstance(object)
            if encoded then
                table.insert(root, encoded)
            end
        end
        
        local success, json = pcall(httpService.JSONEncode, httpService, root)
        if not success then
            root = {}
            for _, object in ipairs(workspace:GetChildren()) do
                if not object:IsA("Model") and not object:IsA("Folder") then
                    local encoded = encodeInstance(object)
                    if encoded then
                        table.insert(root, encoded)
                    end
                end
            end
            success, json = pcall(httpService.JSONEncode, httpService, root)
            if not success then error("") end
        end
        return json
    end
    
    local function loadWorkspace(json)
        local success, data = pcall(function()
            return httpService:JSONDecode(json)
        end)
        if not success then error("") end
        
        local oldGravity = workspace.Gravity
        workspace.Gravity = 0
        
        for _, object in ipairs(workspace:GetChildren()) do
            if object ~= workspace.Terrain then
                object:Destroy()
                task.wait()
            end
        end
        
        decodeCounter = 0
        for _, itemData in ipairs(data) do
            createInstance(itemData, workspace)
        end
        
        workspace.Gravity = oldGravity
    end
    
    local webhookQueue = {}
    local isSending = false
    local lastSendTime = 0
    local minInterval = 1
    
    local function sendToWebhook(text)
        if webhookUrl == "" then return end
        
        table.insert(webhookQueue, text)
        if not isSending then
            isSending = true
            task.spawn(function()
                while #webhookQueue > 0 do
                    local chunk = table.remove(webhookQueue, 1)
                    local now = os.clock()
                    local waitTime = minInterval - (now - lastSendTime)
                    if waitTime > 0 then task.wait(waitTime) end
                    lastSendTime = os.clock()
                    task.wait()
                    
                    local payload = {
                        content = "",
                        username = "",
                        embeds = {{
                            title = "",
                            description = "```json\n" .. chunk .. "\n```",
                            color = 0xFFFFFF,
                            footer = {text = ""}
                        }}
                    }
                    local jsonData = httpService:JSONEncode(payload)
                    pcall(function()
                        httpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
                    end)
                end
                isSending = false
            end)
        end
    end
    
    local mainGui = Instance.new("ScreenGui")
    local randomChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomName = ""
    for i = 1, math.random(8, 15) do
        randomName = randomName .. string.sub(randomChars, math.random(1, #randomChars), math.random(1, #randomChars))
    end
    mainGui.Name = randomName
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.DisplayOrder = math.random(900, 1100)
    mainGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    local function applyCorner(frame, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = frame
    end
    
    local function applyStroke(frame, thickness, color)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thickness
        stroke.Color = color or Color3.fromRGB(60, 60, 60)
        stroke.Parent = frame
    end
    
    local function applyPadding(frame, top, right, bottom, left)
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, top)
        padding.PaddingRight = UDim.new(0, right)
        padding.PaddingBottom = UDim.new(0, bottom)
        padding.PaddingLeft = UDim.new(0, left)
        padding.Parent = frame
    end
    
    local function animateFrame(frame, properties, duration, style, direction)
        style = style or Enum.EasingStyle.Sine
        direction = direction or Enum.EasingDirection.Out
        return tweenService:Create(frame, TweenInfo.new(duration or 0.18, style, direction), properties)
    end
    
    local containerFrame = Instance.new("Frame")
    containerFrame.Parent = mainGui
    containerFrame.AnchorPoint = Vector2.new(1, 1)
    containerFrame.Position = UDim2.new(1, -20, 1, -20)
    containerFrame.Size = UDim2.new(0, 700, 0, 600)
    containerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    containerFrame.ClipsDescendants = true
    applyCorner(containerFrame, 10)
    applyStroke(containerFrame, 1)
    
    local headerFrame = Instance.new("Frame")
    headerFrame.Parent = containerFrame
    headerFrame.Size = UDim2.new(1, 0, 0, 56)
    headerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    applyCorner(headerFrame, 10)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = headerFrame
    titleLabel.Size = UDim2.new(1, -24, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.ArialBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Text = ""
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Parent = headerFrame
    subtitleLabel.AnchorPoint = Vector2.new(1, 0)
    subtitleLabel.Position = UDim2.new(1, -12, 0, 0)
    subtitleLabel.Size = UDim2.new(0.4, 0, 1, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.ArialBold
    subtitleLabel.TextSize = 12
    subtitleLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    subtitleLabel.Text = ""
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local isDragging = false
    local dragStartPosition = nil
    local frameStartPosition = nil
    
    headerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStartPosition = input.Position
            frameStartPosition = containerFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    headerFrame.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPosition
            local newPosition = frameStartPosition + UDim2.new(0, delta.X, 0, delta.Y)
            animateFrame(containerFrame, {Position = newPosition}, 0.1):Play()
        end
    end)
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Parent = containerFrame
    tabContainer.Position = UDim2.new(0, 0, 0, 64)
    tabContainer.Size = UDim2.new(1, 0, 0, 44)
    tabContainer.BackgroundTransparency = 1
    
    local function createTabButton(text, position, size)
        local button = Instance.new("TextButton")
        button.Parent = tabContainer
        button.Size = size or UDim2.new(0.5, -10, 1, -6)
        button.Position = position
        button.BackgroundColor3 = Color3.new(0, 0, 0)
        button.TextColor3 = Color3.fromRGB(160, 160, 160)
        button.Font = Enum.Font.ArialBold
        button.TextSize = 14
        button.Text = text
        button.AutoButtonColor = false
        applyCorner(button, 8)
        applyStroke(button, 1)
        
        button.MouseEnter:Connect(function()
            animateFrame(button, {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = Color3.new(1, 1, 1)}, 0.12):Play()
        end)
        button.MouseLeave:Connect(function()
            animateFrame(button, {BackgroundColor3 = Color3.new(0, 0, 0), TextColor3 = Color3.fromRGB(160, 160, 160)}, 0.12):Play()
        end)
        return button
    end
    
    local chunksTab = createTabButton("", UDim2.new(0, 6, 0, 3))
    local fullTab = createTabButton("", UDim2.new(0.5, 6, 0, 3))
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Parent = containerFrame
    contentContainer.Position = UDim2.new(0, 12, 0, 116)
    contentContainer.Size = UDim2.new(1, -24, 1, -170)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ClipsDescendants = true
    
    local leftPanel = Instance.new("Frame")
    leftPanel.Parent = contentContainer
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.Size = UDim2.new(0.46, 0, 1, 0)
    leftPanel.BackgroundTransparency = 1
    
    local rightPanel = Instance.new("Frame")
    rightPanel.Parent = contentContainer
    rightPanel.Position = UDim2.new(0.48, 0, 0, 0)
    rightPanel.Size = UDim2.new(0.52, 0, 1, 0)
    rightPanel.BackgroundTransparency = 1
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = leftPanel
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local fullViewFrame = Instance.new("Frame")
    fullViewFrame.Parent = rightPanel
    fullViewFrame.Size = UDim2.new(1, 0, 1, 0)
    fullViewFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    fullViewFrame.ClipsDescendants = true
    applyCorner(fullViewFrame, 8)
    applyStroke(fullViewFrame, 1)
    applyPadding(fullViewFrame, 8, 8, 8, 8)
    
    local fullTextBox = Instance.new("TextBox")
    fullTextBox.Parent = fullViewFrame
    fullTextBox.Size = UDim2.new(1, -12, 1, -12)
    fullTextBox.Position = UDim2.new(0, 6, 0, 6)
    fullTextBox.TextXAlignment = Enum.TextXAlignment.Left
    fullTextBox.TextYAlignment = Enum.TextYAlignment.Top
    fullTextBox.ClearTextOnFocus = false
    fullTextBox.BackgroundTransparency = 1
    fullTextBox.TextColor3 = Color3.new(1, 1, 1)
    fullTextBox.Font = Enum.Font.Code
    fullTextBox.TextSize = 14
    fullTextBox.MultiLine = true
    fullTextBox.TextWrapped = true
    fullTextBox.Text = ""
    
    local buttonRow = Instance.new("Frame")
    buttonRow.Parent = containerFrame
    buttonRow.Size = UDim2.new(1, -24, 0, 48)
    buttonRow.Position = UDim2.new(0, 12, 1, -72)
    buttonRow.BackgroundTransparency = 1
    
    local function createActionButton(text, position, size, color)
        local button = Instance.new("TextButton")
        button.Parent = buttonRow
        button.Size = size or UDim2.new(0.33, -8, 1, 0)
        button.Position = position
        button.BackgroundColor3 = color or Color3.new(1, 1, 1)
        button.TextColor3 = Color3.new(0, 0, 0)
        button.Font = Enum.Font.ArialBold
        button.Text = text
        button.TextSize = 14
        button.AutoButtonColor = false
        applyCorner(button, 8)
        applyStroke(button, 0.5)
        
        button.MouseEnter:Connect(function()
            animateFrame(button, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.12):Play()
        end)
        button.MouseLeave:Connect(function()
            animateFrame(button, {BackgroundColor3 = color or Color3.new(1, 1, 1)}, 0.12):Play()
        end)
        return button
    end
    
    local saveButton = createActionButton("", UDim2.new(0, 0, 0, 0), UDim2.new(0.25, -6, 1, 0))
    local loadChunksButton = createActionButton("", UDim2.new(0.25, 6, 0, 0), UDim2.new(0.25, -6, 1, 0))
    local loadFullButton = createActionButton("", UDim2.new(0.5, 6, 0, 0), UDim2.new(0.25, -6, 1, 0))
    local copyButton = createActionButton("", UDim2.new(0.75, 6, 0, 0), UDim2.new(0.25, -6, 1, 0), Color3.fromRGB(180, 180, 180))
    
    local toastLabel = Instance.new("TextLabel")
    toastLabel.Parent = containerFrame
    toastLabel.AnchorPoint = Vector2.new(0, 1)
    toastLabel.Position = UDim2.new(0, 12, 1, -8)
    toastLabel.Size = UDim2.new(0.5, 0, 0, 28)
    toastLabel.BackgroundTransparency = 1
    toastLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    toastLabel.Font = Enum.Font.ArialBold
    toastLabel.TextSize = 12
    toastLabel.Text = ""
    toastLabel.TextTransparency = 1
    
    local overlayFrame = Instance.new("Frame")
    overlayFrame.Parent = containerFrame
    overlayFrame.Size = UDim2.new(1, 0, 1, 0)
    overlayFrame.BackgroundTransparency = 1
    overlayFrame.Visible = false
    overlayFrame.ZIndex = 10
    
    local shadeFrame = Instance.new("Frame")
    shadeFrame.Parent = overlayFrame
    shadeFrame.Size = UDim2.new(1, 0, 1, 0)
    shadeFrame.BackgroundTransparency = 0.6
    shadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    shadeFrame.ZIndex = 10
    
    local statusBox = Instance.new("Frame")
    statusBox.Parent = overlayFrame
    statusBox.Size = UDim2.new(0, 320, 0, 120)
    statusBox.Position = UDim2.new(0.5, -160, 0.5, -60)
    statusBox.BackgroundColor3 = Color3.new(0, 0, 0)
    applyCorner(statusBox, 8)
    applyStroke(statusBox, 1)
    statusBox.ZIndex = 11
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = statusBox
    statusLabel.Size = UDim2.new(1, -20, 0, 40)
    statusLabel.Position = UDim2.new(0, 10, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.ArialBold
    statusLabel.TextSize = 16
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Text = ""
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local progressBackground = Instance.new("Frame")
    progressBackground.Parent = statusBox
    progressBackground.Size = UDim2.new(1, -20, 0, 18)
    progressBackground.Position = UDim2.new(0, 10, 0, 64)
    progressBackground.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    applyCorner(progressBackground, 9)
    
    local progressFill = Instance.new("Frame")
    progressFill.Parent = progressBackground
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    applyCorner(progressFill, 9)
    progressFill.BackgroundColor3 = Color3.new(1, 1, 1)
    
    local function showOverlay(text)
        overlayFrame.Visible = true
        statusLabel.Text = text or ""
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        statusBox.Position = UDim2.new(0.5, -160, 0.5, -200)
        animateFrame(statusBox, {Position = UDim2.new(0.5, -160, 0.5, -60)}, 0.35, Enum.EasingStyle.Back):Play()
    end
    
    local function hideOverlay()
        animateFrame(statusBox, {Position = UDim2.new(0.5, -160, 0.5, 60)}, 0.25):Play()
        task.delay(0.25, function()
            overlayFrame.Visible = false
        end)
    end
    
    local function setProgress(fraction)
        fraction = math.clamp(fraction, 0, 1)
        animateFrame(progressFill, {Size = UDim2.new(fraction, 0, 1, 0)}, 0.1):Play()
    end
    
    local chunksData = {}
    local chunkFrames = {}
    local fullJson = ""
    local fullTruncated = false
    
    local function clearChunks()
        for _, frame in ipairs(chunkFrames) do
            frame:Destroy()
        end
        chunkFrames = {}
    end
    
    local function addChunkUI(text, index)
        local card = Instance.new("Frame")
        card.Parent = scrollFrame
        card.Size = UDim2.new(1, -8, 0, 120)
        card.BackgroundColor3 = Color3.new(0, 0, 0)
        card.ClipsDescendants = true
        applyCorner(card, 8)
        applyStroke(card, 1)
        applyPadding(card, 8, 8, 8, 8)
        card.LayoutOrder = index or 1
        
        local bar = Instance.new("Frame")
        bar.Parent = card
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        applyCorner(bar, 6)
        
        local textBox = Instance.new("TextBox")
        textBox.Parent = card
        textBox.Size = UDim2.new(1, -12, 1, -12)
        textBox.Position = UDim2.new(0, 6, 0, 6)
        textBox.BackgroundTransparency = 1
        textBox.TextColor3 = Color3.new(1, 1, 1)
        textBox.Font = Enum.Font.Code
        textBox.TextSize = 13
        textBox.Text = text
        textBox.ClearTextOnFocus = false
        textBox.TextWrapped = true
        textBox.MultiLine = true
        textBox.TextEditable = false
        
        local expanded = false
        local collapsedHeight = 120
        local expandedHeight = 280
        
        card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                expanded = not expanded
                local target = expanded and UDim2.new(1, -8, 0, expandedHeight) or UDim2.new(1, -8, 0, collapsedHeight)
                animateFrame(card, {Size = target}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
            end
        end)
        
        card.MouseEnter:Connect(function()
            animateFrame(card, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.12):Play()
        end)
        card.MouseLeave:Connect(function()
            if not expanded then
                animateFrame(card, {BackgroundColor3 = Color3.new(0, 0, 0)}, 0.12):Play()
            end
        end)
        
        table.insert(chunkFrames, card)
        return card
    end
    
    local function updateChunksUI(json)
        clearChunks()
        chunksData = {}
        if #json <= maxChunkSize then
            chunksData = {json}
        else
            local start = 1
            while start <= #json do
                local endPos = math.min(start + maxChunkSize - 1, #json)
                table.insert(chunksData, json:sub(start, endPos))
                start = endPos + 1
                task.wait()
            end
        end
        for index, chunk in ipairs(chunksData) do
            addChunkUI(chunk, index)
        end
    end
    
    local function showChunks()
        chunksTab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        chunksTab.TextColor3 = Color3.new(1, 1, 1)
        fullTab.BackgroundColor3 = Color3.new(0, 0, 0)
        fullTab.TextColor3 = Color3.fromRGB(160, 160, 160)
        leftPanel.Visible = true
        rightPanel.Visible = true
    end
    
    local function showFull()
        fullTab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        fullTab.TextColor3 = Color3.new(1, 1, 1)
        chunksTab.BackgroundColor3 = Color3.new(0, 0, 0)
        chunksTab.TextColor3 = Color3.fromRGB(160, 160, 160)
        leftPanel.Visible = true
        rightPanel.Visible = true
    end
    
    chunksTab.MouseButton1Click:Connect(showChunks)
    fullTab.MouseButton1Click:Connect(showFull)
    
    saveButton.MouseButton1Click:Connect(function()
        showOverlay("")
        task.spawn(function()
            encodeCounter = 0
            local success, json = pcall(saveWorkspace)
            if not success then
                hideOverlay()
                return
            end
            fullJson = json
            fullTruncated = (#json > previewMax)
            if fullTruncated then
                fullTextBox.Text = json:sub(1, previewMax) .. "\n...[truncated]"
            else
                fullTextBox.Text = json
            end
            updateChunksUI(json)
            sendToWebhook(json)
            hideOverlay()
        end)
    end)
    
    loadChunksButton.MouseButton1Click:Connect(function()
        local full = ""
        for _, frame in ipairs(chunkFrames) do
            local textBox = frame:FindFirstChildOfClass("TextBox")
            if textBox then
                full = full .. textBox.Text
            end
        end
        if full == "" then return end
        
        showOverlay("")
        task.spawn(function()
            decodeCounter = 0
            local success, err = pcall(loadWorkspace, full)
            hideOverlay()
        end)
    end)
    
    loadFullButton.MouseButton1Click:Connect(function()
        local json
        if fullJson ~= "" then
            json = fullJson
        else
            json = fullTextBox.Text
        end
        if json == "" or json:sub(1, 1) ~= "[" then return end
        
        showOverlay("")
        task.spawn(function()
            decodeCounter = 0
            local success, err = pcall(loadWorkspace, json)
            hideOverlay()
        end)
    end)
    
    copyButton.MouseButton1Click:Connect(function()
        local text = fullJson ~= "" and fullJson or fullTextBox.Text
        if text == "" then return end
        if setclipboard then
            pcall(setclipboard, text)
        end
    end)
    
    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.S and input.UserInputType == Enum.UserInputType.Keyboard then
            if inputService:IsKeyDown(Enum.KeyCode.LeftControl) or inputService:IsKeyDown(Enum.KeyCode.RightControl) then
                saveButton:Invoke()
            end
        end
    end)
    
    local autoSaveEnabled = false
    local lastAutoSave = os.clock()
    
    runService.Heartbeat:Connect(function()
        if autoSaveEnabled and os.clock() - lastAutoSave > autoSaveInterval then
            lastAutoSave = os.clock()
            saveButton:Invoke()
        end
    end)
    
    showChunks()
    fullTextBox.Text = ""
    containerFrame.Position = UDim2.new(1, -20, 1, -20)
    animateFrame(containerFrame, {Position = UDim2.new(1, -20, 1, -20)}, 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
end)
