--==========================================================================--
--                Tooling Node Runtime WorkspaceSerializer                  --
------------------------------------------------------------------------------
--   https://github.com/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer   --
--                               By Bondpley                                --
--                                  v.1.2                                   --
--==========================================================================--

local ValueCodec = {}

local function sanitizeNumber(value)
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return 0
        end
    end
    return value
end

function ValueCodec.encodeValue(value)
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
        if value:IsA("LocalScript") or value:IsA("ModuleScript") then
            return {"SCRIPT", value.Name, value.Source}
        elseif value:IsA("Script") then
            return {"SCRIPT", value.Name, "--SS dont save sry!"}
        else
            return nil
        end
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

function ValueCodec.decodeValue(data)
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
            script.Source = data[3]
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

return ValueCodec
