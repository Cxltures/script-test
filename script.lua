loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()

-- Ultimate Player Control System with Auto-Restart
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Persistent configuration system
if not _G.PersistentPlayerSettings then
    _G.PersistentPlayerSettings = {
        hitbox = {
            enabled = true,
            size = 7,
            transparency = 1,
            collision = false
        },
        walkSpeed = {
            enabled = true,
            speed = 15
        },
        rejoin = {
            enabled = true,
            autoRestart = true
        }
    }
end

-- Apply configuration to genv
getgenv().hitboxConfig = _G.PersistentPlayerSettings.hitbox
getgenv().walkSpeedConfig = _G.PersistentPlayerSettings.walkSpeed
getgenv().rejoinConfig = _G.PersistentPlayerSettings.rejoin

-- Local player reference
local localPlayer = Players.LocalPlayer
if not localPlayer then
    localPlayer = Players.PlayerAdded:Wait()
end

-- Enhanced rejoin function with guaranteed persistence
local function rejoin()
    if not getgenv().rejoinConfig.enabled then return end

    _G.PersistentPlayerSettings = {
        hitbox = table.clone(getgenv().hitboxConfig),
        walkSpeed = table.clone(getgenv().walkSpeedConfig),
        rejoin = table.clone(getgenv().rejoinConfig)
    }

    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/Cxltures/script-test/refs/heads/main/toobad.lua'))()")
    elseif queue_on_teleport then
        queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/Cxltures/script-test/refs/heads/main/toobad.lua'))()")
    end

    if #Players:GetPlayers() <= 1 then
        localPlayer:Kick("Rejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
    end
end


-- Hitbox System Functions
local function updateHitboxes()
    if not getgenv().hitboxConfig.enabled then return end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer == localPlayer then continue end
        
        local character = otherPlayer.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Store original values if we haven't already
                if not humanoidRootPart:FindFirstChild("OriginalSize") then
                    local originalSize = Instance.new("Vector3Value")
                    originalSize.Name = "OriginalSize"
                    originalSize.Value = humanoidRootPart.Size
                    originalSize.Parent = humanoidRootPart
                    
                    local originalTransparency = Instance.new("NumberValue")
                    originalTransparency.Name = "OriginalTransparency"
                    originalTransparency.Value = humanoidRootPart.Transparency
                    originalTransparency.Parent = humanoidRootPart
                end
                
                -- Apply hitbox modifications
                humanoidRootPart.Size = Vector3.new(getgenv().hitboxConfig.size, getgenv().hitboxConfig.size, getgenv().hitboxConfig.size)
                humanoidRootPart.Transparency = getgenv().hitboxConfig.transparency
                humanoidRootPart.CanCollide = getgenv().hitboxConfig.collision
            end
        end
    end
end

local function restoreOriginalValues(character)
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local originalSize = humanoidRootPart:FindFirstChild("OriginalSize")
            local originalTransparency = humanoidRootPart:FindFirstChild("OriginalTransparency")
            
            if originalSize then
                humanoidRootPart.Size = originalSize.Value
                originalSize:Destroy()
            end
            
            if originalTransparency then
                humanoidRootPart.Transparency = originalTransparency.Value
                originalTransparency:Destroy()
            end
        end
    end
end

-- WalkSpeed System Functions
local function enforceWalkSpeed(humanoid)
    if humanoid and humanoid.WalkSpeed ~= getgenv().walkSpeedConfig.speed then
        humanoid.WalkSpeed = getgenv().walkSpeedConfig.speed
    end
end

local function setupWalkSpeed(char)
    if not getgenv().walkSpeedConfig.enabled then return end
    
    local humanoid = char:WaitForChild("Humanoid")
    enforceWalkSpeed(humanoid)
    
    if _G.WalkSpeedConnections and _G.WalkSpeedConnections.walkSpeedChanged then
        _G.WalkSpeedConnections.walkSpeedChanged:Disconnect()
    end
    
    if not _G.WalkSpeedConnections then
        _G.WalkSpeedConnections = {}
    end
    
    _G.WalkSpeedConnections.walkSpeedChanged = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        enforceWalkSpeed(humanoid)
    end)
end

-- Initialize systems
local function initSystems()
    -- Hitbox System
    _G.HitboxSystem = {
        connections = { render = {} },
        restore = restoreOriginalValues
    }
    
    -- WalkSpeed System
    if not _G.WalkSpeedConnections then
        _G.WalkSpeedConnections = {
            walkSpeedChanged = nil,
            characterAdded = nil
        }
    end
    
    -- Set up connections
    table.insert(_G.HitboxSystem.connections.render, RunService.RenderStepped:Connect(updateHitboxes))
    
    -- Player management
    Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(character)
            if getgenv().hitboxConfig.enabled then
                updateHitboxes()
            end
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer ~= localPlayer then
            restoreOriginalValues(leavingPlayer.Character)
        end
    end)
    
    -- Initialize for existing players
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer then
            if otherPlayer.Character then
                updateHitboxes()
            end
            otherPlayer.CharacterAdded:Connect(function(character)
                updateHitboxes()
            end)
        end
    end
    
    -- WalkSpeed setup
    _G.WalkSpeedConnections.characterAdded = localPlayer.CharacterAdded:Connect(setupWalkSpeed)
    if localPlayer.Character then
        setupWalkSpeed(localPlayer.Character)
    end
    
    -- Toggle functions
    getgenv().toggleHitboxes = function(enabled)
        getgenv().hitboxConfig.enabled = enabled
        _G.PersistentPlayerSettings.hitbox.enabled = enabled
        if not enabled then
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= localPlayer then
                    restoreOriginalValues(otherPlayer.Character)
                end
            end
        else
            updateHitboxes()
        end
    end
    
    getgenv().toggleWalkSpeed = function(enabled)
        getgenv().walkSpeedConfig.enabled = enabled
        _G.PersistentPlayerSettings.walkSpeed.enabled = enabled
        if enabled and localPlayer.Character then
            setupWalkSpeed(localPlayer.Character)
        end
    end
    
    getgenv().toggleRejoin = function(enabled)
        getgenv().rejoinConfig.enabled = enabled
        _G.PersistentPlayerSettings.rejoin.enabled = enabled
    end
    
    getgenv().toggleAutoRestart = function(enabled)
        getgenv().rejoinConfig.autoRestart = enabled
        _G.PersistentPlayerSettings.rejoin.autoRestart = enabled
        print("Auto-restart on rejoin:", enabled and "ENABLED" or "DISABLED")
    end
    
    -- Cleanup functions
    getgenv().cleanupHitboxes = function()
        getgenv().toggleHitboxes(false)
        if _G.HitboxSystem then
            for _, connection in pairs(_G.HitboxSystem.connections.render) do
                connection:Disconnect()
            end
            _G.HitboxSystem = nil
        end
    end
    
    getgenv().cleanupWalkSpeed = function()
        getgenv().toggleWalkSpeed(false)
        if _G.WalkSpeedConnections then
            if _G.WalkSpeedConnections.walkSpeedChanged then
                _G.WalkSpeedConnections.walkSpeedChanged:Disconnect()
            end
            if _G.WalkSpeedConnections.characterAdded then
                _G.WalkSpeedConnections.characterAdded:Disconnect()
            end
            _G.WalkSpeedConnections = nil
        end
    end
    
    getgenv().disableSystems = function()
        getgenv().cleanupHitboxes()
        getgenv().cleanupWalkSpeed()
        _G.PersistentPlayerSettings.rejoin.autoRestart = false
    end
    
    -- Automatic restart check
    if _G.PersistentPlayerSettings.rejoin.autoRestart then
        print("Auto-restart was enabled on previous session - settings preserved")
    end
end

-- Initialize the systems
initSystems()

-- Manual triggers:
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        getgenv().toggleHitboxes(not getgenv().hitboxConfig.enabled)
        print("Hitboxes:", getgenv().hitboxConfig.enabled and "ENABLED" or "DISABLED")
    elseif input.KeyCode == Enum.KeyCode.F6 then
        getgenv().toggleWalkSpeed(not getgenv().walkSpeedConfig.enabled)
        print("WalkSpeed:", getgenv().walkSpeedConfig.enabled and "ENABLED" or "DISABLED")
    elseif input.KeyCode == Enum.KeyCode.F7 then
        if getgenv().rejoinConfig.enabled then
            print("Rejoining game...")
            rejoin()
        else
            print("Rejoin is disabled! Enable with getgenv().toggleRejoin(true)")
        end
    elseif input.KeyCode == Enum.KeyCode.F8 then
        getgenv().toggleAutoRestart(not getgenv().rejoinConfig.autoRestart)
    elseif input.KeyCode == Enum.KeyCode.Insert then
        getgenv().disableSystems()
        print("All systems cleaned up")
    end
end)
