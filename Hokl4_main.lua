-- Hokl4 Main Script - 作者: Yux6 整合版
-- 整合了AlienX冷脚本和矢井凛源码功能

-- 初始化变量
local lp = game:GetService("Players").LocalPlayer
local character = lp.Character or lp.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- 通知函数
function Notify(title, text, duration)
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

-- 通用功能模块
CommonFeatures = {
    -- 飞行功能
    FlyEnabled = false,
    FlySpeed = 50,
    
    ToggleFly = function(self, state)
        self.FlyEnabled = state
        if state then
            Notify("Hokl4", "飞行模式已开启", 2)
            spawn(function()
                while self.FlyEnabled do
                    if hrp then
                        local moveDir = Vector3.new(
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) and 1 or 0)
                        )
                        
                        hrp.Velocity = moveDir.Unit * self.FlySpeed
                    end
                    wait(0.01)
                end
                hrp.Velocity = Vector3.new(0, 0, 0)
            end)
        else
            Notify("Hokl4", "飞行模式已关闭", 2)
        end
    end,
    
    -- 无碰撞功能
    NoClipEnabled = false,
    
    ToggleNoClip = function(self, state)
        self.NoClipEnabled = state
        if state then
            Notify("Hokl4", "无碰撞已开启", 2)
            spawn(function()
                while self.NoClipEnabled do
                    for _, v in pairs(character:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                    wait(0.01)
                end
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end)
        else
            Notify("Hokl4", "无碰撞已关闭", 2)
        end
    end,
    
    -- 夜视功能
    NightVisionEnabled = false,
    NightVisionEffect = nil,
    
    ToggleNightVision = function(self, state)
        self.NightVisionEnabled = state
        if state then
            Notify("Hokl4", "夜视已开启", 2)
            -- 创建夜视效果
            if not self.NightVisionEffect then
                local overlay = Instance.new("ScreenGui")
                overlay.Name = "NightVisionOverlay"
                overlay.Parent = game:GetService("CoreGui")
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                frame.BackgroundTransparency = 0.9
                frame.Parent = overlay
                
                self.NightVisionEffect = overlay
            else
                self.NightVisionEffect.Enabled = true
            end
        else
            Notify("Hokl4", "夜视已关闭", 2)
            if self.NightVisionEffect then
                self.NightVisionEffect.Enabled = false
            end
        end
    end,
    
    -- 无限跳跃功能
    InfiniteJumpEnabled = false,
    JumpBind = nil,
    
    ToggleInfiniteJump = function(self, state)
        self.InfiniteJumpEnabled = state
        if state then
            Notify("Hokl4", "无限跳跃已开启", 2)
            self.JumpBind = game:GetService("UserInputService").JumpRequest:Connect(function()
                if self.InfiniteJumpEnabled and humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            Notify("Hokl4", "无限跳跃已关闭", 2)
            if self.JumpBind then
                self.JumpBind:Disconnect()
                self.JumpBind = nil
            end
        end
    end,
    
    -- 设置移动速度
    SetWalkSpeed = function(self, speed)
        if humanoid then
            humanoid.WalkSpeed = speed
            Notify("Hokl4", "移动速度已设置为 " .. speed, 1)
        end
    end,
    
    -- 设置跳跃力量
    SetJumpPower = function(self, power)
        if humanoid then
            humanoid.JumpPower = power
            Notify("Hokl4", "跳跃力量已设置为 " .. power, 1)
        end
    end,
    
    -- 透视功能
    ESPEnabled = false,
    ESPParts = {},
    
    ToggleESP = function(self, state)
        self.ESPEnabled = state
        if state then
            Notify("Hokl4", "透视已开启", 2)
            self:SetupCharacterESP()
            -- 监听玩家加入
            game:GetService("Players").PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function(char)
                    if self.ESPEnabled then
                        self:SetupCharacterESP(char)
                    end
                end)
            end)
        else
            Notify("Hokl4", "透视已关闭", 2)
            self:RemovePlayerESP()
        end
    end,
    
    -- 设置角色透视
    SetupCharacterESP = function(self, char)
        if char then
            -- 为指定角色设置ESP
            self:AddESPToCharacter(char)
        else
            -- 为所有玩家设置ESP
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player ~= lp and player.Character then
                    self:AddESPToCharacter(player.Character)
                end
            end
        end
    end,
    
    -- 为角色添加ESP
    AddESPToCharacter = function(self, character)
        if not character then return end
        
        -- 创建BoxHandleAdornment
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESPBox"
        box.Adornee = character:FindFirstChild("HumanoidRootPart") or character
        box.Size = Vector3.new(4, 5, 2)
        box.Color3 = Color3.fromRGB(255, 0, 0)
        box.AlwaysOnTop = true
        box.Transparency = 0.3
        box.ZIndex = 5
        box.Parent = character
        
        -- 创建玩家名称标签
        local nameTag = Instance.new("BillboardGui")
        nameTag.Name = "ESPName"
        nameTag.AlwaysOnTop = true
        nameTag.Size = UDim2.new(0, 200, 0, 50)
        nameTag.StudsOffset = Vector3.new(0, 3, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = game:GetService("Players"):GetPlayerFromCharacter(character).Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = nameTag
        
        nameTag.Parent = character:FindFirstChild("HumanoidRootPart") or character
        
        -- 保存ESP部件引用
        if not self.ESPParts[character] then
            self.ESPParts[character] = {box = box, nameTag = nameTag}
        end
    end,
    
    -- 移除玩家透视
    RemovePlayerESP = function(self)
        for character, parts in pairs(self.ESPParts) do
            if parts.box and parts.box.Parent then
                parts.box:Destroy()
            end
            if parts.nameTag and parts.nameTag.Parent then
                parts.nameTag:Destroy()
            end
        end
        self.ESPParts = {}
    end
}

-- 游戏特定模块
GameModules = {
    -- 99 Nights 模块
    Night99 = {
        KillAuraEnabled = false,
        AutoTreeEnabled = false,
        AutoEatEnabled = false,
        GodModeEnabled = false,
        
        ToggleKillAura = function(self, state)
            self.KillAuraEnabled = state
            if state then
                Notify("Hokl4", "杀戮光环已开启", 2)
                spawn(function()
                    while self.KillAuraEnabled do
                        -- 杀戮光环逻辑
                        for _, mob in pairs(workspace:GetDescendants()) do
                            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                                if (mob.HumanoidRootPart.Position - hrp.Position).Magnitude < 15 then
                                    -- 攻击逻辑
                                    game:GetService("ReplicatedStorage").Remotes:FindFirstChild("HitMob"):FireServer(mob)
                                end
                            end
                        end
                        wait(0.1)
                    end
                end)
            else
                Notify("Hokl4", "杀戮光环已关闭", 2)
            end
        end,
        
        ToggleAutoTree = function(self, state)
            self.AutoTreeEnabled = state
            if state then
                Notify("Hokl4", "自动砍树已开启", 2)
                spawn(function()
                    while self.AutoTreeEnabled do
                        -- 自动砍树逻辑
                        for _, tree in pairs(workspace:GetDescendants()) do
                            if tree:IsA("BasePart") and tree.Name == "Tree" then
                                if (tree.Position - hrp.Position).Magnitude < 10 then
                                    -- 砍树逻辑
                                    game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ChopTree"):FireServer(tree)
                                end
                            end
                        end
                        wait(0.5)
                    end
                end)
            else
                Notify("Hokl4", "自动砍树已关闭", 2)
            end
        end,
        
        ToggleAutoEat = function(self, state)
            self.AutoEatEnabled = state
            if state then
                Notify("Hokl4", "自动进食已开启", 2)
                spawn(function()
                    while self.AutoEatEnabled do
                        -- 自动进食逻辑
                        if lp.Character and lp.Character.Humanoid.Health < lp.Character.Humanoid.MaxHealth then
                            -- 使用食物逻辑
                            for _, food in pairs(lp.Backpack:GetChildren()) do
                                if food.Name:find("Food") then
                                    food.Parent = lp.Character
                                    wait(0.1)
                                    break
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "自动进食已关闭", 2)
            end
        end,
        
        ToggleGodMode = function(self, state)
            self.GodModeEnabled = state
            if state then
                Notify("Hokl4", "无敌模式已开启", 2)
                spawn(function()
                    while self.GodModeEnabled do
                        if humanoid then
                            humanoid.Health = humanoid.MaxHealth
                        end
                        wait(0.1)
                    end
                end)
            else
                Notify("Hokl4", "无敌模式已关闭", 2)
            end
        end
    },
    
    -- Blade Ball 模块
    BladeBall = {
        AutoHitEnabled = false,
        AutoDodgeEnabled = false,
        
        ToggleAutoHit = function(self, state)
            self.AutoHitEnabled = state
            if state then
                Notify("Hokl4", "自动击球已开启", 2)
                spawn(function()
                    while self.AutoHitEnabled do
                        -- 自动击球逻辑
                        local ball = workspace:FindFirstChild("Ball")
                        if ball and ball:IsA("BasePart") then
                            if (ball.Position - hrp.Position).Magnitude < 10 then
                                -- 击球逻辑
                                game:GetService("ReplicatedStorage").Remotes:FindFirstChild("HitBall"):FireServer()
                            end
                        end
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "自动击球已关闭", 2)
            end
        end,
        
        ToggleAutoDodge = function(self, state)
            self.AutoDodgeEnabled = state
            if state then
                Notify("Hokl4", "自动闪避已开启", 2)
                spawn(function()
                    while self.AutoDodgeEnabled do
                        -- 自动闪避逻辑
                        local ball = workspace:FindFirstChild("Ball")
                        if ball and ball:IsA("BasePart") then
                            local direction = (hrp.Position - ball.Position).Unit
                            hrp.Velocity = direction * 50
                        end
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "自动闪避已关闭", 2)
            end
        end
    }
}

-- 新增游戏模块 - 整合AlienX冷脚本和矢井凛源码功能
GameModules = setmetatable(GameModules, {
    __index = function(self, key)
        return rawget(self, key) or {
            -- 默认空模块
        }
    end
})

-- 加载冷脚本功能
function LoadColdScripts()
    -- Doors 功能
    GameModules.Doors = {
        AutoCollect = false,
        GodMode = false,
        
        ToggleAutoCollect = function(self, state)
            self.AutoCollect = state
            if state then
                Notify("Hokl4", "Doors自动收集已开启", 2)
                spawn(function()
                    while self.AutoCollect do
                        -- 自动收集逻辑
                        for _, item in pairs(workspace:GetDescendants()) do
                            if item:IsA("BasePart") and (item.Name:find("Key") or item.Name:find("Item")) then
                                if (item.Position - hrp.Position).Magnitude < 15 then
                                    hrp.CFrame = CFrame.new(item.Position)
                                    wait(0.5)
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "Doors自动收集已关闭", 2)
            end
        end,
        
        ToggleGodMode = function(self, state)
            self.GodMode = state
            if state then
                Notify("Hokl4", "Doors无敌模式已开启", 2)
                spawn(function()
                    while self.GodMode do
                        if humanoid then
                            humanoid.Health = humanoid.MaxHealth
                        end
                        wait(0.1)
                    end
                end)
            else
                Notify("Hokl4", "Doors无敌模式已关闭", 2)
            end
        end
    }
    
    -- 伐木大亨功能
    GameModules.LoggingTycoon = {
        AutoChop = false,
        AutoSell = false,
        
        ToggleAutoChop = function(self, state)
            self.AutoChop = state
            if state then
                Notify("Hokl4", "伐木大亨自动砍树已开启", 2)
                spawn(function()
                    while self.AutoChop do
                        -- 自动砍树逻辑
                        for _, tree in pairs(workspace:GetDescendants()) do
                            if tree:IsA("Model") and tree:FindFirstChild("Trunk") then
                                if (tree.Trunk.Position - hrp.Position).Magnitude < 8 then
                                    -- 砍树逻辑
                                    game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Chop"):FireServer(tree)
                                    wait(2)
                                end
                            end
                        end
                        wait(0.5)
                    end
                end)
            else
                Notify("Hokl4", "伐木大亨自动砍树已关闭", 2)
            end
        end,
        
        ToggleAutoSell = function(self, state)
            self.AutoSell = state
            if state then
                Notify("Hokl4", "伐木大亨自动出售已开启", 2)
                spawn(function()
                    while self.AutoSell do
                        -- 自动出售逻辑
                        local sellPart = workspace:FindFirstChild("SellArea")
                        if sellPart then
                            hrp.CFrame = CFrame.new(sellPart.Position)
                            game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Sell"):FireServer()
                        end
                        wait(5)
                    end
                end)
            else
                Notify("Hokl4", "伐木大亨自动出售已关闭", 2)
            end
        end
    }
    
    -- 俄亥俄州功能
    GameModules.Ohio = {
        AutoLoot = false,
        SpeedBoost = false,
        
        ToggleAutoLoot = function(self, state)
            self.AutoLoot = state
            if state then
                Notify("Hokl4", "俄亥俄州自动拾取已开启", 2)
                spawn(function()
                    while self.AutoLoot do
                        -- 自动拾取逻辑
                        for _, item in pairs(workspace:GetDescendants()) do
                            if item:IsA("BasePart") and item.Name:find("Loot") then
                                if (item.Position - hrp.Position).Magnitude < 20 then
                                    hrp.CFrame = CFrame.new(item.Position)
                                    wait(0.2)
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "俄亥俄州自动拾取已关闭", 2)
            end
        end,
        
        ToggleSpeedBoost = function(self, state)
            self.SpeedBoost = state
            if state then
                Notify("Hokl4", "俄亥俄州速度提升已开启", 2)
                if humanoid then
                    humanoid.WalkSpeed = 100
                end
            else
                Notify("Hokl4", "俄亥俄州速度提升已关闭", 2)
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    }
    
    -- 火箭发射模拟器功能
    GameModules.RocketSimulator = {
        AutoBuild = false,
        AutoLaunch = false,
        
        ToggleAutoBuild = function(self, state)
            self.AutoBuild = state
            if state then
                Notify("Hokl4", "火箭模拟器自动建造已开启", 2)
                spawn(function()
                    while self.AutoBuild do
                        -- 自动建造逻辑
                        local buildParts = workspace:FindFirstChild("BuildParts")
                        if buildParts then
                            for _, part in pairs(buildParts:GetChildren()) do
                                if part:IsA("BasePart") then
                                    -- 建造逻辑
                                    game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Build"):FireServer(part)
                                    wait(0.5)
                                end
                            end
                        end
                        wait(2)
                    end
                end)
            else
                Notify("Hokl4", "火箭模拟器自动建造已关闭", 2)
            end
        end,
        
        ToggleAutoLaunch = function(self, state)
            self.AutoLaunch = state
            if state then
                Notify("Hokl4", "火箭模拟器自动发射已开启", 2)
                spawn(function()
                    while self.AutoLaunch do
                        -- 自动发射逻辑
                        local launchButton = workspace:FindFirstChild("LaunchButton")
                        if launchButton then
                            hrp.CFrame = CFrame.new(launchButton.Position)
                            game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Launch"):FireServer()
                        end
                        wait(10)
                    end
                end)
            else
                Notify("Hokl4", "火箭模拟器自动发射已关闭", 2)
            end
        end
    }
    
    -- 力量传奇功能
    GameModules.PowerLegend = {
        AutoTrain = false,
        AutoRebirth = false,
        
        ToggleAutoTrain = function(self, state)
            self.AutoTrain = state
            if state then
                Notify("Hokl4", "力量传奇自动训练已开启", 2)
                spawn(function()
                    while self.AutoTrain do
                        -- 自动训练逻辑
                        local trainingAreas = workspace:FindFirstChild("TrainingAreas")
                        if trainingAreas then
                            for _, area in pairs(trainingAreas:GetChildren()) do
                                hrp.CFrame = CFrame.new(area.Position)
                                wait(2)
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "力量传奇自动训练已关闭", 2)
            end
        end,
        
        ToggleAutoRebirth = function(self, state)
            self.AutoRebirth = state
            if state then
                Notify("Hokl4", "力量传奇自动重生已开启", 2)
                spawn(function()
                    while self.AutoRebirth do
                        -- 自动重生逻辑
                        game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Rebirth"):FireServer()
                        wait(10)
                    end
                end)
            else
                Notify("Hokl4", "力量传奇自动重生已关闭", 2)
            end
        end
    }
    
    -- 矢井凛源码功能 - 机会预判瞄准
    GameModules.AimAssist = {
        PredictionEnabled = false,
        
        TogglePrediction = function(self, state)
            self.PredictionEnabled = state
            if state then
                Notify("Hokl4", "机会预判瞄准已开启", 2)
                spawn(function()
                    while self.PredictionEnabled do
                        -- 机会预判瞄准逻辑
                        local closestPlayer = nil
                        local closestDistance = math.huge
                        
                        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local distance = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                                if distance < closestDistance and distance < 100 then
                                    closestDistance = distance
                                    closestPlayer = player
                                end
                            end
                        end
                        
                        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            -- 瞄准逻辑
                            local targetPos = closestPlayer.Character.HumanoidRootPart.Position
                            -- 预测目标移动
                            local targetVel = closestPlayer.Character.HumanoidRootPart.Velocity
                            local predictedPos = targetPos + (targetVel * 0.2)
                            
                            -- 设置视角
                            local camera = workspace.CurrentCamera
                            camera.CFrame = CFrame.new(camera.CFrame.Position, predictedPos)
                        end
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "机会预判瞄准已关闭", 2)
            end
        end
    }
end

-- 加载冷脚本功能
LoadColdScripts()

-- 传送功能
function GameModules:TeleportToPlayer(playerName)
    local targetPlayer = game:GetService("Players"):FindFirstChild(playerName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        Notify("Hokl4", "已传送到 " .. playerName, 3)
    else
        Notify("Hokl4", "无法找到玩家 " .. playerName, 3)
    end
end

function GameModules:TeleportToCoords(x, y, z)
    hrp.CFrame = CFrame.new(x, y, z)
    Notify("Hokl4", "已传送到坐标: " .. x .. ", " .. y .. ", " .. z, 3)
end

-- 玩家列表
function GameModules:GetPlayerList()
    local players = {}
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        table.insert(players, player.Name)
    end
    return players
end

-- 初始化UI
function InitUI()
    -- 创建ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "Hokl4_GUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game:GetService("CoreGui")
    
    -- 创建主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.8
    mainFrame.BorderColor3 = Color3.fromRGB(60, 180, 240)
    mainFrame.BorderSizePixel = 2
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    -- 创建标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
    titleBar.Parent = mainFrame
    
    -- 标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Hokl4 - 整合版脚本"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Tab 容器
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Position = UDim2.new(0, 0, 0, 30)
    tabContainer.Size = UDim2.new(1, 0, 0, 30)
    tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabContainer.Parent = mainFrame
    
    -- 内容容器
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Position = UDim2.new(0, 0, 0, 60)
    contentContainer.Size = UDim2.new(1, 0, 1, -60)
    contentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ScrollBarThickness = 5
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = mainFrame
    
    -- 创建Tabs - 增加新游戏功能标签
    local tabs = {
        {name = "通用功能", module = CommonFeatures},
        {name = "99 Nights", module = GameModules.Night99},
        {name = "Blade Ball", module = GameModules.BladeBall},
        {name = "传送", module = GameModules},
        {name = "Doors", module = GameModules.Doors},
        {name = "伐木大亨", module = GameModules.LoggingTycoon},
        {name = "俄亥俄州", module = GameModules.Ohio},
        {name = "火箭模拟器", module = GameModules.RocketSimulator},
        {name = "力量传奇", module = GameModules.PowerLegend},
        {name = "矢井凛功能", module = GameModules.AimAssist}
    }
    
    local currentTab = nil
    local tabButtons = {}
    local tabContents = {}
    
    -- 创建Tab按钮和内容（使用滚动标签栏）
    local tabScrollFrame = Instance.new("ScrollingFrame")
    tabScrollFrame.Name = "TabScrollFrame"
    tabScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    tabScrollFrame.CanvasSize = UDim2.new(0, #tabs * 100, 0, 0)
    tabScrollFrame.BackgroundTransparency = 1
    tabScrollFrame.ScrollBarThickness = 0
    tabScrollFrame.Parent = tabContainer
    
    -- 创建Tab按钮和内容
    for i, tab in ipairs(tabs) do
        -- 创建Tab按钮
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.name .. "Button"
        tabButton.Position = UDim2.new(0, (i-1)*100, 0, 0)
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.Text = tab.name
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.TextSize = 12
        tabButton.Font = Enum.Font.Gotham
        tabButton.Parent = tabScrollFrame
        tabButtons[tab.name] = tabButton
        
        -- 创建Tab内容
        local tabContent = Instance.new("Frame")
        tabContent.Name = tab.name .. "Content"
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.Parent = contentContainer
        tabContents[tab.name] = tabContent
        
        -- Tab按钮点击事件
        tabButton.MouseButton1Click:Connect(function()
            if currentTab then
                tabButtons[currentTab].BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                tabButtons[currentTab].TextColor3 = Color3.fromRGB(200, 200, 200)
                tabContents[currentTab].Visible = false
            end
            
            currentTab = tab.name
            tabButton.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabContent.Visible = true
            
            -- 调整CanvasSize以适应内容
            local totalHeight = 0
            for _, child in pairs(tabContent:GetChildren()) do
                if child:IsA("GuiObject") then
                    totalHeight = math.max(totalHeight, child.Position.Y.Offset + child.Size.Y.Offset)
                end
            end
            contentContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
        end)
    end
    
    -- 通用功能Tab内容
    local commonContent = tabContents["通用功能"]
    local yPos = 10
    
    -- 飞行开关
    local flyToggle = CreateToggle(commonContent, "飞行模式", "FlyToggle", function(state)
        CommonFeatures:ToggleFly(state)
    end)
    flyToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无碰撞开关
    local noclipToggle = CreateToggle(commonContent, "无碰撞", "NoClipToggle", function(state)
        CommonFeatures:ToggleNoClip(state)
    end)
    noclipToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 夜视开关
    local nightVisionToggle = CreateToggle(commonContent, "夜视", "NightVisionToggle", function(state)
        CommonFeatures:ToggleNightVision(state)
    end)
    nightVisionToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无限跳跃开关
    local infiniteJumpToggle = CreateToggle(commonContent, "无限跳跃", "InfiniteJumpToggle", function(state)
        CommonFeatures:ToggleInfiniteJump(state)
    end)
    infiniteJumpToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 透视开关
    local espToggle = CreateToggle(commonContent, "透视", "ESPToggle", function(state)
        CommonFeatures:ToggleESP(state)
    end)
    espToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 移动速度滑块
    local speedLabel = CreateLabel(commonContent, "移动速度", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    local speedSlider = CreateSlider(commonContent, "SpeedSlider", 16, 16, 500, function(value)
        CommonFeatures:SetWalkSpeed(value)
    end)
    speedSlider.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 跳跃力量滑块
    local jumpLabel = CreateLabel(commonContent, "跳跃力量", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    local jumpSlider = CreateSlider(commonContent, "JumpSlider", 50, 50, 500, function(value)
        CommonFeatures:SetJumpPower(value)
    end)
    jumpSlider.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 99 Nights Tab内容
    local night99Content = tabContents["99 Nights"]
    yPos = 10
    
    -- 杀戮光环开关
    local killAuraToggle = CreateToggle(night99Content, "杀戮光环", "KillAuraToggle", function(state)
        GameModules.Night99:ToggleKillAura(state)
    end)
    killAuraToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动砍树开关
    local autoTreeToggle = CreateToggle(night99Content, "自动砍树", "AutoTreeToggle", function(state)
        GameModules.Night99:ToggleAutoTree(state)
    end)
    autoTreeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动进食开关
    local autoEatToggle = CreateToggle(night99Content, "自动进食", "AutoEatToggle", function(state)
        GameModules.Night99:ToggleAutoEat(state)
    end)
    autoEatToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无敌模式开关
    local godModeToggle = CreateToggle(night99Content, "无敌模式", "GodModeToggle", function(state)
        GameModules.Night99:ToggleGodMode(state)
    end)
    godModeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- Blade Ball Tab内容
    local bladeBallContent = tabContents["Blade Ball"]
    yPos = 10
    
    -- 自动击球开关
    local autoHitToggle = CreateToggle(bladeBallContent, "自动击球", "AutoHitToggle", function(state)
        GameModules.BladeBall:ToggleAutoHit(state)
    end)
    autoHitToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动闪避开关
    local autoDodgeToggle = CreateToggle(bladeBallContent, "自动闪避", "AutoDodgeToggle", function(state)
        GameModules.BladeBall:ToggleAutoDodge(state)
    end)
    autoDodgeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 传送Tab内容
    local teleportContent = tabContents["传送"]
    yPos = 10
    
    -- 玩家列表下拉菜单
    local playerDropdown = CreateDropdown(teleportContent, "选择玩家", "PlayerDropdown", GameModules:GetPlayerList(), function(selected)
        teleportContent.PlayerName = selected
    end)
    playerDropdown.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 传送到玩家按钮
    local teleportButton = CreateButton(teleportContent, "传送到玩家", "TeleportButton", function()
        if teleportContent.PlayerName then
            GameModules:TeleportToPlayer(teleportContent.PlayerName)
        else
            Notify("Hokl4", "请先选择玩家", 3)
        end
    end)
    teleportButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 刷新玩家列表按钮
    local refreshButton = CreateButton(teleportContent, "刷新玩家列表", "RefreshButton", function()
        -- 重新创建下拉菜单
        if teleportContent:FindFirstChild("PlayerDropdown") then
            teleportContent.PlayerDropdown:Destroy()
        end
        
        local newDropdown = CreateDropdown(teleportContent, "选择玩家", "PlayerDropdown", GameModules:GetPlayerList(), function(selected)
            teleportContent.PlayerName = selected
        end)
        newDropdown.Position = UDim2.new(0, 10, 0, 10)
    end)
    refreshButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- Doors Tab内容
    local doorsContent = tabContents["Doors"]
    yPos = 10
    
    -- 自动收集开关
    local autoCollectToggle = CreateToggle(doorsContent, "自动收集", "DoorsAutoCollectToggle", function(state)
        GameModules.Doors:ToggleAutoCollect(state)
    end)
    autoCollectToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无敌模式开关
    local doorsGodModeToggle = CreateToggle(doorsContent, "无敌模式", "DoorsGodModeToggle", function(state)
        GameModules.Doors:ToggleGodMode(state)
    end)
    doorsGodModeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 伐木大亨Tab内容
    local loggingContent = tabContents["伐木大亨"]
    yPos = 10
    
    -- 自动砍树开关
    local loggingAutoChopToggle = CreateToggle(loggingContent, "自动砍树", "LoggingAutoChopToggle", function(state)
        GameModules.LoggingTycoon:ToggleAutoChop(state)
    end)
    loggingAutoChopToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动出售开关
    local loggingAutoSellToggle = CreateToggle(loggingContent, "自动出售", "LoggingAutoSellToggle", function(state)
        GameModules.LoggingTycoon:ToggleAutoSell(state)
    end)
    loggingAutoSellToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 俄亥俄州Tab内容
    local ohioContent = tabContents["俄亥俄州"]
    yPos = 10
    
    -- 自动拾取开关
    local ohioAutoLootToggle = CreateToggle(ohioContent, "自动拾取", "OhioAutoLootToggle", function(state)
        GameModules.Ohio:ToggleAutoLoot(state)
    end)
    ohioAutoLootToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 速度提升开关
    local ohioSpeedBoostToggle = CreateToggle(ohioContent, "速度提升", "OhioSpeedBoostToggle", function(state)
        GameModules.Ohio:ToggleSpeedBoost(state)
    end)
    ohioSpeedBoostToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 火箭模拟器Tab内容
    local rocketContent = tabContents["火箭模拟器"]
    yPos = 10
    
    -- 自动建造开关
    local rocketAutoBuildToggle = CreateToggle(rocketContent, "自动建造", "RocketAutoBuildToggle", function(state)
        GameModules.RocketSimulator:ToggleAutoBuild(state)
    end)
    rocketAutoBuildToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动发射开关
    local rocketAutoLaunchToggle = CreateToggle(rocketContent, "自动发射", "RocketAutoLaunchToggle", function(state)
        GameModules.RocketSimulator:ToggleAutoLaunch(state)
    end)
    rocketAutoLaunchToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 力量传奇Tab内容
    local powerContent = tabContents["力量传奇"]
    yPos = 10
    
    -- 自动训练开关
    local powerAutoTrainToggle = CreateToggle(powerContent, "自动训练", "PowerAutoTrainToggle", function(state)
        GameModules.PowerLegend:ToggleAutoTrain(state)
    end)
    powerAutoTrainToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动重生开关
    local powerAutoRebirthToggle = CreateToggle(powerContent, "自动重生", "PowerAutoRebirthToggle", function(state)
        GameModules.PowerLegend:ToggleAutoRebirth(state)
    end)
    powerAutoRebirthToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 矢井凛功能Tab内容
    local aimContent = tabContents["矢井凛功能"]
    yPos = 10
    
    -- 机会预判瞄准开关
    local aimPredictionToggle = CreateToggle(aimContent, "机会预判瞄准", "AimPredictionToggle", function(state)
        GameModules.AimAssist:TogglePrediction(state)
    end)
    aimPredictionToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 选择第一个Tab
    tabButtons[tabs[1].name]:FireEvent("MouseButton1Click")
    
    -- 创建工具函数
    function CreateLabel(parent, text, position)
        local label = Instance.new("TextLabel")
        label.Name = text .. "Label"
        label.Position = position
        label.Size = UDim2.new(1, -20, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.Parent = parent
        return label
    end
    
    function CreateToggle(parent, text, name, callback)
        local toggle = Instance.new("Frame")
        toggle.Name = name
        toggle.Size = UDim2.new(1, -20, 0, 25)
        toggle.BackgroundTransparency = 1
        toggle.Parent = parent
        
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "Label"
        toggleLabel.Position = UDim2.new(0, 0, 0, 0)
        toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Text = text
        toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleLabel.TextSize = 14
        toggleLabel.Font = Enum.Font.Gotham
        toggleLabel.Parent = toggle
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "Button"
        toggleButton.Position = UDim2.new(0.75, 0, 0, 2.5)
        toggleButton.Size = UDim2.new(0.2, 0, 0, 20)
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        toggleButton.Text = "关"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.TextSize = 12
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.Parent = toggle
        
        local isEnabled = false
        toggleButton.MouseButton1Click:Connect(function()
            isEnabled = not isEnabled
            toggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
            toggleButton.Text = isEnabled and "开" or "关"
            callback(isEnabled)
        end)
        
        return toggle
    end
    
    function CreateButton(parent, text, name, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -20, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.GothamBold
        button.Parent = parent
        
        button.MouseButton1Click:Connect(callback)
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        end)
        
        return button
    end
    
    function CreateSlider(parent, name, defaultValue, minValue, maxValue, callback)
        local slider = Instance.new("Frame")
        slider.Name = name
        slider.Size = UDim2.new(1, -20, 0, 30)
        slider.BackgroundTransparency = 1
        slider.Parent = parent
        
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Position = UDim2.new(0, 0, 0, 12.5)
        sliderTrack.Size = UDim2.new(1, 0, 0, 5)
        sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        sliderTrack.Parent = slider
        
        local sliderHandle = Instance.new("Frame")
        sliderHandle.Name = "Handle"
        sliderHandle.Size = UDim2.new(0, 15, 0, 15)
        sliderHandle.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
        sliderHandle.Parent = slider
        
        -- 计算初始位置
        local valueRange = maxValue - minValue
        local initialValue = defaultValue - minValue
        local initialPercent = initialValue / valueRange
        sliderHandle.Position = UDim2.new(initialPercent, 0, 0.5, 0)
        
        -- 创建值显示标签
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Position = UDim2.new(1, -50, 0, 0)
        valueLabel.Size = UDim2.new(0, 50, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(defaultValue)
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = 12
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.Parent = slider
        
        -- 拖动处理
        local dragging = false
        sliderHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                game:GetService("UserInputService"):SetMouseIconEnabled(false)
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                game:GetService("UserInputService"):SetMouseIconEnabled(true)
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position
                local absPos = slider.AbsolutePosition
                local absSize = slider.AbsoluteSize
                
                -- 计算相对位置
                local relX = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
                sliderHandle.Position = UDim2.new(relX, 0, 0.5, 0)
                
                -- 计算值
                local value = math.floor(relX * valueRange + minValue)
                valueLabel.Text = tostring(value)
                callback(value)
            end
        end)
        
        return slider
    end
    
    function CreateDropdown(parent, text, name, options, callback)
        local dropdown = Instance.new("Frame")
        dropdown.Name = name
        dropdown.Size = UDim2.new(1, -20, 0, 25)
        dropdown.BackgroundTransparency = 1
        dropdown.Parent = parent
        
        local dropdownLabel = Instance.new("TextLabel")
        dropdownLabel.Name = "Label"
        dropdownLabel.Position = UDim2.new(0, 0, 0, 0)
        dropdownLabel.Size = UDim2.new(0.4, 0, 1, 0)
        dropdownLabel.BackgroundTransparency = 1
        dropdownLabel.Text = text
        dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownLabel.TextSize = 14
        dropdownLabel.Font = Enum.Font.Gotham
        dropdownLabel.Parent = dropdown
        
        local dropdownButton = Instance.new("TextButton")
        dropdownButton.Name = "Button"
        dropdownButton.Position = UDim2.new(0.4, 0, 0, 0)
        dropdownButton.Size = UDim2.new(0.6, 0, 1, 0)
        dropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownButton.Text = options[1] or "无选项"
        dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownButton.TextSize = 12
        dropdownButton.Font = Enum.Font.Gotham
        dropdownButton.Parent = dropdown
        
        local dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Name = "List"
        dropdownList.Position = UDim2.new(0.4, 0, 1, 0)
        dropdownList.Size = UDim2.new(0.6, 0, 0, 100)
        dropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownList.BackgroundTransparency = 0
        dropdownList.Visible = false
        dropdownList.ScrollBarThickness = 5
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 25)
        dropdownList.Parent = dropdown
        
        -- 创建选项
        for i, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option" .. i
            optionButton.Position = UDim2.new(0, 0, 0, (i-1)*25)
            optionButton.Size = UDim2.new(1, 0, 0, 25)
            optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.TextSize = 12
            optionButton.Font = Enum.Font.Gotham
            optionButton.Parent = dropdownList
            
            optionButton.MouseButton1Click:Connect(function()
                dropdownButton.Text = option
                dropdownList.Visible = false
                callback(option)
            end)
            
            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end)
            
            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end)
        end
        
        -- 切换下拉列表
        dropdownButton.MouseButton1Click:Connect(function()
            dropdownList.Visible = not dropdownList.Visible
        end)
        
        -- 点击外部关闭
        game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                local absPos = dropdown.AbsolutePosition
                local absSize = dropdown.AbsoluteSize
                
                if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                   mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                    dropdownList.Visible = false
                end
            end
        end)
        
        return dropdown
    end
    
    -- 窗口拖动功能
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 初始化脚本
Notify("Hokl4", "脚本加载成功! 作者: Yux6", 3)

-- 初始化UI
task.spawn(function()
    pcall(InitUI)
end)

-- 保持脚本运行
while true do
    wait(60)
end