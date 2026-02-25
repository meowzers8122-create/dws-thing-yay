if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(0.5)

--------------------------------------------------
-- Load Rayfield
--------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--------------------------------------------------
-- Window
--------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "dws thing yay",
	LoadingTitle = "dws thing yay",
	LoadingSubtitle = "Dandy's World Survival",
	ConfigurationSaving = { Enabled = false }
})

--------------------------------------------------
-- Tabs (decals preserved)
--------------------------------------------------
local MainTab   = Window:CreateTab("Main", 88445602271509)
local SelfTab   = Window:CreateTab("Self", 129908947680826)
local OthersTab = Window:CreateTab("Others", 138294552266079)
local MiscTab   = Window:CreateTab("Misc", 77077345162683)

--------------------------------------------------
-- Services
--------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

--------------------------------------------------
-- Globals
--------------------------------------------------
local activeToggle = nil
local ESP_REFRESH = 0.1

--------------------------------------------------
-- Cooldown Logic (Merged)
--------------------------------------------------
local function inAir()
	local c = LP.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position.Y > 20
end

local function getCooldown(toon)
	-- Cocoa always has its own cooldown
	if toon == "Cocoa" then
		return 0.45
	end

	-- Air cooldown for everyone else
	if inAir() then
		return 0.3
	end

	return 0.1
end

--------------------------------------------------
-- Warning
--------------------------------------------------
local function notifyWarning()
	Rayfield:Notify({
		Title = "Warning",
		Content = "Enabling more than one will break!",
		Duration = 5,
		Image = 136727402635215
	})
end

--------------------------------------------------
-- MAIN TAB
--------------------------------------------------
MainTab:CreateButton({
	Name = "Join Dandy's World Survival",
	Callback = function()
		TeleportService:Teleport(107612301456655, LP)
	end
})

--------------------------------------------------
-- SELF TAB
--------------------------------------------------
SelfTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {1,100},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(v)
		local h = LP.Character and LP.Character:FindFirstChild("Humanoid")
		if h then h.WalkSpeed = v end
	end
})

SelfTab:CreateSlider({
	Name = "JumpPower",
	Range = {1,100},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v)
		local h = LP.Character and LP.Character:FindFirstChild("Humanoid")
		if h then h.JumpPower = v end
	end
})

--------------------------------------------------
-- Ability Toggle System
--------------------------------------------------
local function createToggle(name, toonName, mode)
	local running = false
	local recent = {}

	OthersTab:CreateToggle({
		Name = name,
		Callback = function(v)
			if v then
				if activeToggle then
					notifyWarning()
					return
				end
				activeToggle = name
				running = true

				task.spawn(function()
					while running do
						pcall(function()
							RS.Remotes.MorphEvent:InvokeServer(
								RS.Toons:WaitForChild(toonName)
							)
						end)

						local targets = {}

						for _,p in ipairs(Players:GetPlayers()) do
							local char = p.Character
							local hum = char and char:FindFirstChild("Humanoid")
							local hrp = char and char:FindFirstChild("HumanoidRootPart")
							if hum and hrp then
								if mode == "heal" and hum.Health < hum.MaxHealth then
									table.insert(targets,p)
								elseif mode == "near" and (hrp.Position - LP.Character.HumanoidRootPart.Position).Magnitude <= 40 and not table.find(recent,p) then
									table.insert(targets,p)
								elseif mode == "recent" and not table.find(recent,p) then
									table.insert(targets,p)
								elseif mode == "normal" then
									table.insert(targets,p)
								end
							end
						end

						if #targets > 0 then
							local chosen = targets[math.random(#targets)]
							pcall(function()
								RS.Remotes.AbilityEvent:InvokeServer(chosen.Character)
							end)
							if mode == "near" or mode == "recent" then
								table.insert(recent, chosen)
								if #recent > 5 then table.remove(recent,1) end
							end
						end

						task.wait(getCooldown(toonName))
					end
				end)
			else
				running = false
				activeToggle = nil
			end
		end
	})
end

--------------------------------------------------
-- OTHERS TAB (Abilities)
--------------------------------------------------
createToggle("Spam Heal as Sprout","Sprout","heal")
createToggle("Spam Heal as Cosmo","Cosmo","heal")
createToggle("Spam Heal as Jack","Jack","heal")

createToggle("Spam Ability as Vee","Vee","normal")
createToggle("Spam BonBons as Cocoa","Cocoa","normal")
createToggle("Spam Gust as Flyte","Flyte","normal")

createToggle("Spam Boost as Shelly","Shelly","recent")
createToggle("Spam Hug as Goob","Goob","near")
createToggle("Spam Boost as Tisha","Tisha","normal")

createToggle("Spam Shine as Brightney","Brightney","normal")
createToggle("Spam Scout as Coal","Coal","normal")
createToggle("Spam Boost as Gourdy","Gourdy","normal")

--------------------------------------------------
-- ESP SYSTEM (FINAL, STYLED)
--------------------------------------------------
local ESP = {
	Capsules = false,
	Items = false,
	Toons = false,
	Twisteds = false,
	Objects = {}
}

local function clearESP(obj)
	if ESP.Objects[obj] then
		for _,v in ipairs(ESP.Objects[obj]) do
			if v then v:Destroy() end
		end
		ESP.Objects[obj] = nil
	end
end

local function applyESP(obj, text, color)
	if not obj or ESP.Objects[obj] then return end

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.6 -- softer inside color
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = obj
	highlight.Parent = obj

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 28)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = obj:FindFirstChild("Head") or obj.PrimaryPart or obj
	billboard.Parent = obj

	-- Text
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 14 -- smaller text
	label.TextScaled = false
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(1,1,1) -- white outline
	label.TextStrokeTransparency = 0
	label.Parent = billboard

	ESP.Objects[obj] = {highlight, billboard}
end

--------------------------------------------------
-- ESP SCANNER LOOP
--------------------------------------------------
task.spawn(function()
	while true do
		task.wait(ESP_REFRESH)

		for _,obj in ipairs(workspace:GetDescendants()) do
			-- Research Capsules
			if ESP.Capsules and obj:IsA("Model") and obj.Name:lower():find("capsule") then
				applyESP(obj, "Capsule", Color3.fromRGB(0, 255, 255))

			-- Items
			elseif ESP.Items and obj:IsA("Model") and obj.Name:lower():find("item") then
				applyESP(obj, "Item", Color3.fromRGB(255, 255, 0))

			-- Players / Toons
			elseif ESP.Toons and obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
				applyESP(obj, obj.Name, Color3.fromRGB(0, 255, 0))

			-- Twisteds
			elseif ESP.Twisteds and obj:IsA("Model") and obj.Name:lower():find("twisted") then
				applyESP(obj, "Twisted", Color3.fromRGB(255, 0, 0))
			end
		end

		-- Cleanup
		for obj,_ in pairs(ESP.Objects) do
			if not obj.Parent then
				clearESP(obj)
			end
		end
	end
end)

--------------------------------------------------
-- ESP TOGGLES (UNCHANGED)
--------------------------------------------------
MiscTab:CreateToggle({Name="ESP Research Capsules", Callback=function(v) ESP.Capsules = v end})
MiscTab:CreateToggle({Name="ESP Items", Callback=function(v) ESP.Items = v end})
MiscTab:CreateToggle({Name="ESP Toons", Callback=function(v) ESP.Toons = v end})
MiscTab:CreateToggle({Name="ESP Twisteds", Callback=function(v) ESP.Twisteds = v end})

--------------------------------------------------
-- FULLBRIGHT (MOVED TO MISC)
--------------------------------------------------
MiscTab:CreateToggle({
	Name = "FullBright (No Fog)",
	Callback = function(v)
		if v then
			Lighting.Brightness = 5
			Lighting.ClockTime = 14
			Lighting.FogEnd = 1e9
		else
			Lighting.Brightness = 2
			Lighting.ClockTime = 12
			Lighting.FogEnd = 1000
		end
	end
})

--------------------------------------------------
-- ANTI-LAG TOGGLE
--------------------------------------------------
local AntiLagEnabled = false
MiscTab:CreateToggle({
	Name = "Anti Lag",
	Callback = function(v)
		AntiLagEnabled = v
		if v then
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 1e9
			Lighting.Brightness = 2

			for _,obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter")
				or obj:IsA("Trail")
				or obj:IsA("Smoke")
				or obj:IsA("Fire")
				or obj:IsA("Sparkles") then
					obj.Enabled = false
				elseif obj:IsA("Decal") or obj:IsA("Texture") then
					obj.Transparency = 1
				end
			end
		else
			Lighting.GlobalShadows = true
		end
	end
})

--------------------------------------------------
-- CREATOR DETECTOR
--------------------------------------------------
local creators = {["dandyworldig"]=true,["cupcakeunisprinkies"]=true}

local function checkCreator(p)
	if creators[p.Name:lower()] then
		Rayfield:Notify({
			Title = "Creator of Script in server",
			Content = p.Name..", the creator is in the server!",
			Duration = 8,
       Image = 117767617547071
		})
	end
end

for _,p in ipairs(Players:GetPlayers()) do checkCreator(p) end
Players.PlayerAdded:Connect(checkCreator)

--------------------------------------------------
-- RANDOM NOTIFICATIONS
--------------------------------------------------
local tips = {
	"yo. what time is it? go check it.",
	"remember to get rest and be healthy",
	"don't forget to stay hydrated. and eat. ok",
	"huge credits to the goobispowerful script"
}

task.spawn(function()
	while true do
		task.wait(180)
		Rayfield:Notify({
			Title = "Hey!",
			Content = tips[math.random(#tips)],
			Duration = 6,
			Image = 82764643173420
		})
	end
end)

--------------------------------------------------
-- END OF SCRIPT
--------------------------------------------------
