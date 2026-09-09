--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local MatchState = require(ReplicatedStorage.VaultBreakers.Shared.MatchState)
local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)
local RewardPool = require(ReplicatedStorage.VaultBreakers.Config.RewardPool)
local Types = require(ReplicatedStorage.VaultBreakers.Shared.Types)
local AudiovisualController = require(script.Parent.Controllers.AudiovisualController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

print("[Vault Breakers] Initializing Complete 'The Vault' Lobby Hub & Leaderboard...")

-- 1. Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VaultBreakersUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

AudiovisualController.init(screenGui)

-- 2. Top Live Show Broadcast Header Bar (Collapsible + Marquee Ticker)
local topBar = Instance.new("Frame")
topBar.Name = "LiveBroadcastHeader"
topBar.Size = UDim2.new(1, -40, 0, 48)
topBar.Position = UDim2.new(0, 20, 0, 14)
topBar.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
topBar.BackgroundTransparency = 0.1
topBar.BorderSizePixel = 0
topBar.ClipsDescendants = true
topBar.Parent = screenGui

local tbCorner = Instance.new("UICorner"); tbCorner.CornerRadius = UDim.new(0, 8); tbCorner.Parent = topBar
local tbStroke = Instance.new("UIStroke"); tbStroke.Color = Color3.fromRGB(245, 184, 0); tbStroke.Thickness = 1.2; tbStroke.Transparency = 0.3; tbStroke.Parent = topBar

-- Logo [V] 金库之夜 THE VAULT
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 170, 1, 0)
logoFrame.Position = UDim2.new(0, 10, 0, 0)
logoFrame.BackgroundTransparency = 1
logoFrame.ZIndex = 5
logoFrame.Parent = topBar

local logoBadge = Instance.new("TextLabel")
logoBadge.Size = UDim2.new(0, 30, 0, 30)
logoBadge.Position = UDim2.new(0, 0, 0.5, -15)
logoBadge.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
logoBadge.TextColor3 = Color3.fromRGB(10, 12, 16)
logoBadge.Font = Enum.Font.GothamBold
logoBadge.TextSize = 20
logoBadge.Text = "V"
logoBadge.ZIndex = 5
logoBadge.Parent = logoFrame
local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0, 6); lbc.Parent = logoBadge

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, -38, 0, 34)
logoText.Position = UDim2.new(0, 38, 0.5, -17)
logoText.BackgroundTransparency = 1
logoText.TextColor3 = Color3.fromRGB(255, 205, 60)
logoText.Font = Enum.Font.GothamBold
logoText.TextSize = 15
logoText.TextXAlignment = Enum.TextXAlignment.Left
logoText.Text = "金库之夜\nTHE VAULT"
logoText.ZIndex = 5
logoText.Parent = logoFrame

-- Marquee Ticker Container (Smooth Horizontal Scrolling Ticker)
local tickerContainer = Instance.new("Frame")
tickerContainer.Name = "TickerContainer"
tickerContainer.Size = UDim2.new(1, -440, 1, 0)
tickerContainer.Position = UDim2.new(0, 180, 0, 0)
tickerContainer.BackgroundTransparency = 1
tickerContainer.ClipsDescendants = true
tickerContainer.Parent = topBar

local tickerTextFull = "★ 奖池注入 ¥50,000  ◆  ★ 上轮挑战者在第 11 层金库全部归零  ◆  ⚠ 本轮奖金池 ¥12,000,000  ◆  ★ 正在进行：地下金库真人秀  ◆  十秒读秒，两个按钮。拿钱走人，还是赌上一切翻倍？一人进，亿万出。            "
local tickerLabel = Instance.new("TextLabel")
tickerLabel.Name = "TickerLabel"
tickerLabel.Size = UDim2.new(0, 1600, 1, 0)
tickerLabel.Position = UDim2.new(0, 0, 0, 0)
tickerLabel.BackgroundTransparency = 1
tickerLabel.TextColor3 = Color3.fromRGB(255, 225, 120)
tickerLabel.Font = Enum.Font.GothamMedium
tickerLabel.TextSize = 14
tickerLabel.TextXAlignment = Enum.TextXAlignment.Left
tickerLabel.Text = tickerTextFull .. tickerTextFull
tickerLabel.Parent = tickerContainer

local scrollSpeed = 45
local tickerOffset = 0
RunService.RenderStepped:Connect(function(dt: number)
	tickerOffset += scrollSpeed * dt
	if tickerOffset >= 800 then
		tickerOffset = 0
	end
	tickerLabel.Position = UDim2.new(0, -tickerOffset, 0, 0)
end)

-- Right Section: LIVE tag + Leaderboard quick button + Collapse Button
local rightSection = Instance.new("Frame")
rightSection.Size = UDim2.new(0, 240, 1, 0)
rightSection.Position = UDim2.new(1, -245, 0, 0)
rightSection.BackgroundTransparency = 1
rightSection.ZIndex = 5
rightSection.Parent = topBar

local liveTag = Instance.new("Frame")
liveTag.Size = UDim2.new(0, 115, 0, 28)
liveTag.Position = UDim2.new(0, 0, 0.5, -14)
liveTag.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
liveTag.ZIndex = 5
liveTag.Parent = rightSection
local ltC = Instance.new("UICorner"); ltC.CornerRadius = UDim.new(0, 6); ltC.Parent = liveTag

local liveDot = Instance.new("Frame")
liveDot.Size = UDim2.new(0, 7, 0, 7)
liveDot.Position = UDim2.new(0, 8, 0.5, -3)
liveDot.BackgroundColor3 = Color3.fromRGB(255, 45, 60)
liveDot.ZIndex = 6
liveDot.Parent = liveTag
local ldC = Instance.new("UICorner"); ldC.CornerRadius = UDim.new(1, 0); ldC.Parent = liveDot

local liveText = Instance.new("TextLabel")
liveText.Size = UDim2.new(1, -20, 1, 0)
liveText.Position = UDim2.new(0, 20, 0, 0)
liveText.BackgroundTransparency = 1
liveText.TextColor3 = Color3.fromRGB(255, 215, 0)
liveText.Font = Enum.Font.GothamBold
liveText.TextSize = 11
liveText.TextXAlignment = Enum.TextXAlignment.Left
liveText.Text = "LIVE 47,392"
liveText.ZIndex = 6
liveText.Parent = liveTag

local topLeaderboardBtn = Instance.new("TextButton")
topLeaderboardBtn.Size = UDim2.new(0, 75, 0, 28)
topLeaderboardBtn.Position = UDim2.new(0, 122, 0.5, -14)
topLeaderboardBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
topLeaderboardBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
topLeaderboardBtn.Font = Enum.Font.GothamBold
topLeaderboardBtn.TextSize = 12
topLeaderboardBtn.Text = "🏆 榜单"
topLeaderboardBtn.ZIndex = 6
topLeaderboardBtn.Parent = rightSection
local tlbC = Instance.new("UICorner"); tlbC.CornerRadius = UDim.new(0, 6); tlbC.Parent = topLeaderboardBtn

local toggleBarBtn = Instance.new("TextButton")
toggleBarBtn.Name = "ToggleBarButton"
toggleBarBtn.Size = UDim2.new(0, 30, 0, 28)
toggleBarBtn.Position = UDim2.new(1, -34, 0.5, -14)
toggleBarBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 56)
toggleBarBtn.TextColor3 = Color3.fromRGB(255, 195, 30)
toggleBarBtn.Font = Enum.Font.GothamBold
toggleBarBtn.TextSize = 14
toggleBarBtn.Text = "▲"
toggleBarBtn.ZIndex = 7
toggleBarBtn.Parent = rightSection
local tbBtnC = Instance.new("UICorner"); tbBtnC.CornerRadius = UDim.new(0, 6); tbBtnC.Parent = toggleBarBtn

local isBarCollapsed = false
toggleBarBtn.MouseButton1Click:Connect(function()
	isBarCollapsed = not isBarCollapsed
	local targetPos = if isBarCollapsed then UDim2.new(0, 20, 0, -42) else UDim2.new(0, 20, 0, 14)
	toggleBarBtn.Text = if isBarCollapsed then "▼" else "▲"
	TweenService:Create(topBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	}):Play()
end)

-- 3. American Game Show Newspaper Presentation Modal (The Vault Daily Gazette)
local gazetteModal = Instance.new("Frame")
gazetteModal.Name = "GazetteNewspaperModal"
gazetteModal.Size = UDim2.new(0, 720, 0, 490)
gazetteModal.Position = UDim2.new(0.5, -360, 0.5, -245)
gazetteModal.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
gazetteModal.BorderSizePixel = 0
gazetteModal.Visible = true
gazetteModal.ZIndex = 30
gazetteModal.Parent = screenGui

local gmCorner = Instance.new("UICorner"); gmCorner.CornerRadius = UDim.new(0, 12); gmCorner.Parent = gazetteModal
local gmStroke = Instance.new("UIStroke"); gmStroke.Color = Color3.fromRGB(245, 184, 0); gmStroke.Thickness = 1.8; gmStroke.Parent = gazetteModal

-- Gazette Header / Masthead
local gazetteMasthead = Instance.new("Frame")
gazetteMasthead.Size = UDim2.new(1, -24, 0, 84)
gazetteMasthead.Position = UDim2.new(0, 12, 0, 12)
gazetteMasthead.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
gazetteMasthead.BorderSizePixel = 0
gazetteMasthead.ZIndex = 31
gazetteMasthead.Parent = gazetteModal
local gmhC = Instance.new("UICorner"); gmhC.CornerRadius = UDim.new(0, 8); gmhC.Parent = gazetteMasthead
local gmhS = Instance.new("UIStroke"); gmhS.Color = Color3.fromRGB(245, 184, 0); gmhS.Thickness = 1; gmhS.Transparency = 0.5; gmhS.Parent = gazetteMasthead

local mastheadTopTag = Instance.new("TextLabel")
mastheadTopTag.Size = UDim2.new(1, -60, 0, 18)
mastheadTopTag.Position = UDim2.new(0, 16, 0, 8)
mastheadTopTag.BackgroundTransparency = 1
mastheadTopTag.TextColor3 = Color3.fromRGB(200, 210, 225)
mastheadTopTag.Font = Enum.Font.GothamMedium
mastheadTopTag.TextSize = 11
mastheadTopTag.TextXAlignment = Enum.TextXAlignment.Left
mastheadTopTag.Text = "★ THE VAULT CHRONICLE • 创刊第03季 • 全球第一收视率高风险真人秀 • 独家早报"
mastheadTopTag.ZIndex = 32
mastheadTopTag.Parent = gazetteMasthead

local mastheadMainTitle = Instance.new("TextLabel")
mastheadMainTitle.Size = UDim2.new(1, -80, 0, 36)
mastheadMainTitle.Position = UDim2.new(0, 16, 0, 26)
mastheadMainTitle.BackgroundTransparency = 1
mastheadMainTitle.TextColor3 = Color3.fromRGB(255, 205, 50)
mastheadMainTitle.Font = Enum.Font.GothamBold
mastheadMainTitle.TextSize = 28
mastheadMainTitle.TextXAlignment = Enum.TextXAlignment.Left
mastheadMainTitle.Text = "金 库 特 刊  //  THE DAILY VAULT"
mastheadMainTitle.ZIndex = 32
mastheadMainTitle.Parent = gazetteMasthead

local mastheadSub = Instance.new("TextLabel")
mastheadSub.Size = UDim2.new(1, -80, 0, 18)
mastheadSub.Position = UDim2.new(0, 16, 0, 60)
mastheadSub.BackgroundTransparency = 1
mastheadSub.TextColor3 = Color3.fromRGB(245, 184, 0)
mastheadSub.Font = Enum.Font.GothamMedium
mastheadSub.TextSize = 12
mastheadSub.TextXAlignment = Enum.TextXAlignment.Left
mastheadSub.Text = "今日头条：¥ 12,000,000 巨额现金池已就位！一人进，亿万出，十秒生死博弈。"
mastheadSub.ZIndex = 32
mastheadSub.Parent = gazetteMasthead

-- Close Gazette [ ✕ ] Button (Top Right)
local closeGazetteBtn = Instance.new("TextButton")
closeGazetteBtn.Name = "CloseGazetteButton"
closeGazetteBtn.Size = UDim2.new(0, 34, 0, 34)
closeGazetteBtn.Position = UDim2.new(1, -44, 0, 14)
closeGazetteBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 50)
closeGazetteBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
closeGazetteBtn.Font = Enum.Font.GothamBold
closeGazetteBtn.TextSize = 18
closeGazetteBtn.Text = "✕"
closeGazetteBtn.ZIndex = 33
closeGazetteBtn.Parent = gazetteModal
local cgbC = Instance.new("UICorner"); cgbC.CornerRadius = UDim.new(0, 8); cgbC.Parent = closeGazetteBtn
local cgbS = Instance.new("UIStroke"); cgbS.Color = Color3.fromRGB(245, 184, 0); cgbS.Thickness = 1.2; cgbS.Parent = closeGazetteBtn

-- Gazette Newspaper Content Scroll / Body
local gBody = Instance.new("Frame")
gBody.Size = UDim2.new(1, -24, 0, 310)
gBody.Position = UDim2.new(0, 12, 0, 104)
gBody.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
gBody.ZIndex = 31
gBody.Parent = gazetteModal
local gbC = Instance.new("UICorner"); gbC.CornerRadius = UDim.new(0, 8); gbC.Parent = gBody

-- 3-Step Core Gameplay Cards
local RULES = {
	{
		step = "01",
		title = "锁定专属底牌",
		desc = "演播厅舞台环列 12 座重型精钢金库。登台后挑选 1 座作为你的底牌（价值 ¥1~¥10,000 不等，全场保密）。",
		color = Color3.fromRGB(245, 184, 0),
	},
	{
		step = "02",
		title = "逐轮破译排除",
		desc = "按轮次逐一开启其余金库！每排除一个小奖，剩余奖池均值飙升；一旦误开大奖，均值暴跌！全看你的嗅觉。",
		color = Color3.fromRGB(255, 220, 100),
	},
	{
		step = "03",
		title = "十秒生死决断",
		desc = "每轮结束，幕后 Curator 提出巨额现金报价。十秒倒计时！【拿钱走人】直接提现，或【继续博弈】赌上一切！",
		color = Color3.fromRGB(255, 95, 95),
	},
}

for i, r in ipairs(RULES) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.315, 0, 0, 200)
	card.Position = UDim2.new(0.015 + (i - 1) * 0.33, 0, 0, 14)
	card.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	card.ZIndex = 32
	card.Parent = gBody
	local cdC = Instance.new("UICorner"); cdC.CornerRadius = UDim.new(0, 8); cdC.Parent = card
	local cdS = Instance.new("UIStroke"); cdS.Color = r.color; cdS.Thickness = 1.2; cdS.Transparency = 0.3; cdS.Parent = card

	local stepBadge = Instance.new("TextLabel")
	stepBadge.Size = UDim2.new(0, 36, 0, 24)
	stepBadge.Position = UDim2.new(0, 12, 0, 12)
	stepBadge.BackgroundColor3 = r.color
	stepBadge.TextColor3 = Color3.fromRGB(10, 12, 16)
	stepBadge.Font = Enum.Font.GothamBold
	stepBadge.TextSize = 13
	stepBadge.Text = r.step
	stepBadge.ZIndex = 33
	stepBadge.Parent = card
	local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 4); sbc.Parent = stepBadge

	local cardTitle = Instance.new("TextLabel")
	cardTitle.Size = UDim2.new(1, -60, 0, 24)
	cardTitle.Position = UDim2.new(0, 54, 0, 12)
	cardTitle.BackgroundTransparency = 1
	cardTitle.TextColor3 = Color3.fromRGB(245, 248, 255)
	cardTitle.Font = Enum.Font.GothamBold
	cardTitle.TextSize = 15
	cardTitle.TextXAlignment = Enum.TextXAlignment.Left
	cardTitle.Text = r.title
	cardTitle.ZIndex = 33
	cardTitle.Parent = card

	local cardDesc = Instance.new("TextLabel")
	cardDesc.Size = UDim2.new(1, -24, 1, -50)
	cardDesc.Position = UDim2.new(0, 12, 0, 44)
	cardDesc.BackgroundTransparency = 1
	cardDesc.TextColor3 = Color3.fromRGB(190, 200, 215)
	cardDesc.Font = Enum.Font.Gotham
	cardDesc.TextSize = 13
	cardDesc.TextWrapped = true
	cardDesc.TextXAlignment = Enum.TextXAlignment.Left
	cardDesc.TextYAlignment = Enum.TextYAlignment.Top
	cardDesc.Text = r.desc
	cardDesc.ZIndex = 33
	cardDesc.Parent = card
end

-- Lifeline Banner inside Gazette
local gLifelineBanner = Instance.new("Frame")
gLifelineBanner.Size = UDim2.new(1, -24, 0, 68)
gLifelineBanner.Position = UDim2.new(0, 12, 0, 226)
gLifelineBanner.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
gLifelineBanner.ZIndex = 32
gLifelineBanner.Parent = gBody
local glbC = Instance.new("UICorner"); glbC.CornerRadius = UDim.new(0, 8); glbC.Parent = gLifelineBanner
local glbS = Instance.new("UIStroke"); glbS.Color = Color3.fromRGB(255, 205, 50); glbS.Thickness = 1; glbS.Transparency = 0.5; glbS.Parent = gLifelineBanner

local llIcon = Instance.new("TextLabel")
llIcon.Size = UDim2.new(0, 40, 1, 0)
llIcon.BackgroundTransparency = 1
llIcon.Text = "🕹️"
llIcon.TextSize = 26
llIcon.ZIndex = 33
llIcon.Parent = gLifelineBanner

local llText = Instance.new("TextLabel")
llText.Size = UDim2.new(1, -50, 1, 0)
llText.Position = UDim2.new(0, 46, 0, 0)
llText.BackgroundTransparency = 1
llText.TextColor3 = Color3.fromRGB(240, 245, 255)
llText.Font = Enum.Font.GothamMedium
llText.TextSize = 13
llText.TextXAlignment = Enum.TextXAlignment.Left
llText.Text = "【专属求助特权】中央控制台配有实体操纵杆。犹豫不决？拉下操纵杆触发全服 10 秒观众公投，看民意倒向何方！"
llText.ZIndex = 33
llText.Parent = gLifelineBanner

-- Bottom Buttons in Gazette
local startMatchBtn = Instance.new("TextButton")
startMatchBtn.Name = "StartMatchButton"
startMatchBtn.Size = UDim2.new(0, 220, 0, 46)
startMatchBtn.Position = UDim2.new(0.5, -230, 1, -58)
startMatchBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
startMatchBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
startMatchBtn.Font = Enum.Font.GothamBold
startMatchBtn.TextSize = 17
startMatchBtn.Text = "↖ 立即登台参赛"
startMatchBtn.ZIndex = 32
startMatchBtn.Parent = gazetteModal
local smC = Instance.new("UICorner"); smC.CornerRadius = UDim.new(0, 8); smC.Parent = startMatchBtn

local dismissGazetteBtn = Instance.new("TextButton")
dismissGazetteBtn.Name = "DismissGazetteButton"
dismissGazetteBtn.Size = UDim2.new(0, 220, 0, 46)
dismissGazetteBtn.Position = UDim2.new(0.5, 10, 1, -58)
dismissGazetteBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
dismissGazetteBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
dismissGazetteBtn.Font = Enum.Font.GothamBold
dismissGazetteBtn.TextSize = 15
dismissGazetteBtn.Text = "进入大厅漫步 (✕)"
dismissGazetteBtn.ZIndex = 32
dismissGazetteBtn.Parent = gazetteModal
local dgbC = Instance.new("UICorner"); dgbC.CornerRadius = UDim.new(0, 8); dgbC.Parent = dismissGazetteBtn
local dgbS = Instance.new("UIStroke"); dgbS.Color = Color3.fromRGB(245, 184, 0); dgbS.Thickness = 1.2; dgbS.Parent = dismissGazetteBtn

-- 4. Player Profile & Cash Badge
local profileBadge = Instance.new("Frame")
profileBadge.Name = "ProfileBadge"
profileBadge.Size = UDim2.new(0, 160, 0, 44)
profileBadge.Position = UDim2.new(0, 20, 0, 72)
profileBadge.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
profileBadge.BackgroundTransparency = 0.2
profileBadge.ZIndex = 15
profileBadge.Parent = screenGui
local pbC = Instance.new("UICorner"); pbC.CornerRadius = UDim.new(0, 8); pbC.Parent = profileBadge
local pbS = Instance.new("UIStroke"); pbS.Color = Color3.fromRGB(245, 184, 0); pbS.Thickness = 1.2; pbS.Transparency = 0.4; pbS.Parent = profileBadge

local playerNameLabel = Instance.new("TextLabel")
playerNameLabel.Size = UDim2.new(1, -12, 0, 18)
playerNameLabel.Position = UDim2.new(0, 10, 0, 4)
playerNameLabel.BackgroundTransparency = 1
playerNameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
playerNameLabel.Font = Enum.Font.GothamBold
playerNameLabel.TextSize = 13
playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
playerNameLabel.Text = localPlayer.DisplayName
playerNameLabel.ZIndex = 16
playerNameLabel.Parent = profileBadge

local playerCashLabel = Instance.new("TextLabel")
playerCashLabel.Size = UDim2.new(1, -12, 0, 18)
playerCashLabel.Position = UDim2.new(0, 10, 0, 22)
playerCashLabel.BackgroundTransparency = 1
playerCashLabel.TextColor3 = Color3.fromRGB(255, 205, 50)
playerCashLabel.Font = Enum.Font.GothamMedium
playerCashLabel.TextSize = 12
playerCashLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCashLabel.Text = "💰 筹码：¥ 100,000"
playerCashLabel.ZIndex = 16
playerCashLabel.Parent = profileBadge

-- 5. Left Action Sidebar (背包、商店、玩法、榜单、设置)
local sidebarFrame = Instance.new("Frame")
sidebarFrame.Name = "LeftActionSidebar"
sidebarFrame.Size = UDim2.new(0, 68, 0, 310)
sidebarFrame.Position = UDim2.new(0, 20, 0.5, -135)
sidebarFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
sidebarFrame.BackgroundTransparency = 0.2
sidebarFrame.BorderSizePixel = 0
sidebarFrame.Visible = true
sidebarFrame.ZIndex = 15
sidebarFrame.Parent = screenGui
local sfCorner = Instance.new("UICorner"); sfCorner.CornerRadius = UDim.new(0, 12); sfCorner.Parent = sidebarFrame
local sfStroke = Instance.new("UIStroke"); sfStroke.Color = Color3.fromRGB(245, 184, 0); sfStroke.Thickness = 1.2; sfStroke.Transparency = 0.4; sfStroke.Parent = sidebarFrame

local sfLayout = Instance.new("UIListLayout")
sfLayout.Padding = UDim.new(0, 8)
sfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sfLayout.VerticalAlignment = Enum.VerticalAlignment.Center
sfLayout.Parent = sidebarFrame

local function createSidebarButton(name: string, icon: string, labelText: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 52, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	btn.Text = icon .. "\n" .. labelText
	btn.TextColor3 = Color3.fromRGB(245, 205, 75)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.ZIndex = 16
	btn.Parent = sidebarFrame
	local bC = Instance.new("UICorner"); bC.CornerRadius = UDim.new(0, 8); bC.Parent = btn
	local bS = Instance.new("UIStroke"); bS.Color = Color3.fromRGB(245, 184, 0); bS.Thickness = 1; bS.Transparency = 0.6; bS.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(45, 52, 70) }):Play()
		TweenService:Create(bS, TweenInfo.new(0.2), { Transparency = 0.1 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(22, 26, 36) }):Play()
		TweenService:Create(bS, TweenInfo.new(0.2), { Transparency = 0.6 }):Play()
	end)
	return btn
end

local btnGazette = createSidebarButton("BtnGazette", "📰", "玩法")
local btnInventory = createSidebarButton("BtnInventory", "🎒", "背包")
local btnShop = createSidebarButton("BtnShop", "🛒", "商店")
local lobbyLeaderboardBtn = createSidebarButton("LobbyLeaderboardButton", "🏆", "榜单")
local btnSettings = createSidebarButton("BtnSettings", "⚙️", "设置")

-- 5. Inventory Modal (背包)
local inventoryModal = Instance.new("Frame")
inventoryModal.Name = "InventoryModal"
inventoryModal.Size = UDim2.new(0, 580, 0, 390)
inventoryModal.Position = UDim2.new(0.5, -290, 0.5, -195)
inventoryModal.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
inventoryModal.BorderSizePixel = 0
inventoryModal.Visible = false
inventoryModal.ZIndex = 25
inventoryModal.Parent = screenGui
local imC = Instance.new("UICorner"); imC.CornerRadius = UDim.new(0, 12); imC.Parent = inventoryModal
local imS = Instance.new("UIStroke"); imS.Color = Color3.fromRGB(245, 184, 0); imS.Thickness = 1.6; imS.Parent = inventoryModal

local imHeader = Instance.new("TextLabel")
imHeader.Size = UDim2.new(1, -60, 0, 48)
imHeader.Position = UDim2.new(0, 20, 0, 10)
imHeader.BackgroundTransparency = 1
imHeader.TextColor3 = Color3.fromRGB(255, 205, 50)
imHeader.Font = Enum.Font.GothamBold
imHeader.TextSize = 20
imHeader.TextXAlignment = Enum.TextXAlignment.Left
imHeader.Text = "🎒 挑战者储物柜 // CONTESTANT LOCKER"
imHeader.ZIndex = 26
imHeader.Parent = inventoryModal

local closeInvBtn = Instance.new("TextButton")
closeInvBtn.Size = UDim2.new(0, 32, 0, 32)
closeInvBtn.Position = UDim2.new(1, -44, 0, 16)
closeInvBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
closeInvBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
closeInvBtn.Font = Enum.Font.GothamBold
closeInvBtn.TextSize = 18
closeInvBtn.Text = "✕"
closeInvBtn.ZIndex = 26
closeInvBtn.Parent = inventoryModal
local civC = Instance.new("UICorner"); civC.CornerRadius = UDim.new(0, 6); civC.Parent = closeInvBtn

local invItems = {
	{ icon = "🔮", name = "民意透视镜", qty = "x3", desc = "在公投阶段透视全服观众投票倾向与大盘赔率。" },
	{ icon = "⏱️", name = "决断延时表", qty = "x2", desc = "在 Curator 现金报价读秒阶段额外争取 +5 秒抉择时间。" },
	{ icon = "🛡️", name = "保底挽回险", qty = "x1", desc = "最终回合若开出最低奖金，返还 50% 上轮报价补偿。" },
}

for idx, it in ipairs(invItems) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -40, 0, 82)
	row.Position = UDim2.new(0, 20, 0, 70 + (idx - 1) * 94)
	row.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	row.ZIndex = 26
	row.Parent = inventoryModal
	local rC = Instance.new("UICorner"); rC.CornerRadius = UDim.new(0, 8); rC.Parent = row
	local rS = Instance.new("UIStroke"); rS.Color = Color3.fromRGB(245, 184, 0); rS.Thickness = 1; rS.Transparency = 0.5; rS.Parent = row

	local iIcon = Instance.new("TextLabel")
	iIcon.Size = UDim2.new(0, 60, 1, 0)
	iIcon.BackgroundTransparency = 1
	iIcon.Text = it.icon
	iIcon.TextSize = 34
	iIcon.ZIndex = 27
	iIcon.Parent = row

	local iTitle = Instance.new("TextLabel")
	iTitle.Size = UDim2.new(0, 200, 0, 28)
	iTitle.Position = UDim2.new(0, 64, 0, 12)
	iTitle.BackgroundTransparency = 1
	iTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
	iTitle.Font = Enum.Font.GothamBold
	iTitle.TextSize = 16
	iTitle.TextXAlignment = Enum.TextXAlignment.Left
	iTitle.Text = it.name .. "  " .. it.qty
	iTitle.ZIndex = 27
	iTitle.Parent = row

	local iDesc = Instance.new("TextLabel")
	iDesc.Size = UDim2.new(1, -80, 0, 32)
	iDesc.Position = UDim2.new(0, 64, 0, 42)
	iDesc.BackgroundTransparency = 1
	iDesc.TextColor3 = Color3.fromRGB(180, 190, 205)
	iDesc.Font = Enum.Font.Gotham
	iDesc.TextSize = 13
	iDesc.TextXAlignment = Enum.TextXAlignment.Left
	iDesc.Text = it.desc
	iDesc.ZIndex = 27
	iDesc.Parent = row
end

-- 6. Shop Modal (商店)
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 620, 0, 420)
shopModal.Position = UDim2.new(0.5, -310, 0.5, -210)
shopModal.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
shopModal.BorderSizePixel = 0
shopModal.Visible = false
shopModal.ZIndex = 25
shopModal.Parent = screenGui
local shpC = Instance.new("UICorner"); shpC.CornerRadius = UDim.new(0, 12); shpC.Parent = shopModal
local shpS = Instance.new("UIStroke"); shpS.Color = Color3.fromRGB(245, 184, 0); shpS.Thickness = 1.6; shpS.Parent = shopModal

local shpHeader = Instance.new("TextLabel")
shpHeader.Size = UDim2.new(1, -60, 0, 48)
shpHeader.Position = UDim2.new(0, 20, 0, 10)
shpHeader.BackgroundTransparency = 1
shpHeader.TextColor3 = Color3.fromRGB(255, 205, 50)
shpHeader.Font = Enum.Font.GothamBold
shpHeader.TextSize = 20
shpHeader.TextXAlignment = Enum.TextXAlignment.Left
shpHeader.Text = "🛒 特权黑市商城 // THE VAULT STORE"
shpHeader.ZIndex = 26
shpHeader.Parent = shopModal

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Size = UDim2.new(0, 32, 0, 32)
closeShopBtn.Position = UDim2.new(1, -44, 0, 16)
closeShopBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
closeShopBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
closeShopBtn.Font = Enum.Font.GothamBold
closeShopBtn.TextSize = 18
closeShopBtn.Text = "✕"
closeShopBtn.ZIndex = 26
closeShopBtn.Parent = shopModal
local cshC = Instance.new("UICorner"); cshC.CornerRadius = UDim.new(0, 6); cshC.Parent = closeShopBtn

local shopItems = {
	{ id = "VIP_PASS", icon = "🏆", name = "第三季 VIP 黄金通行证", price = "¥ 88,000", desc = "登台享有专属黄金聚光灯 + 1.5x 连胜加成系数。" },
	{ id = "VAULT_SKIN", icon = "🎨", name = "黑曜石镀金防盗门皮肤", price = "¥ 50,000", desc = "对局中将金库门替换为拉丝纯金机械特效。" },
	{ id = "TACTICAL_PACK", icon = "📦", name = "挑战者战术急救礼包", price = "¥ 30,000", desc = "包含透视镜x3、加时表x2、保底挽回险x1。" },
}

for idx, si in ipairs(shopItems) do
	local sRow = Instance.new("Frame")
	sRow.Size = UDim2.new(1, -40, 0, 92)
	sRow.Position = UDim2.new(0, 20, 0, 70 + (idx - 1) * 106)
	sRow.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	sRow.ZIndex = 26
	sRow.Parent = shopModal
	local srC = Instance.new("UICorner"); srC.CornerRadius = UDim.new(0, 8); srC.Parent = sRow
	local srS = Instance.new("UIStroke"); srS.Color = Color3.fromRGB(245, 184, 0); srS.Thickness = 1; srS.Transparency = 0.5; srS.Parent = sRow

	local sIcon = Instance.new("TextLabel")
	sIcon.Size = UDim2.new(0, 60, 1, 0)
	sIcon.BackgroundTransparency = 1
	sIcon.Text = si.icon
	sIcon.TextSize = 34
	sIcon.ZIndex = 27
	sIcon.Parent = sRow

	local sTitle = Instance.new("TextLabel")
	sTitle.Size = UDim2.new(0, 260, 0, 26)
	sTitle.Position = UDim2.new(0, 64, 0, 14)
	sTitle.BackgroundTransparency = 1
	sTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
	sTitle.Font = Enum.Font.GothamBold
	sTitle.TextSize = 16
	sTitle.TextXAlignment = Enum.TextXAlignment.Left
	sTitle.Text = si.name
	sTitle.ZIndex = 27
	sTitle.Parent = sRow

	local sDesc = Instance.new("TextLabel")
	sDesc.Size = UDim2.new(1, -200, 0, 36)
	sDesc.Position = UDim2.new(0, 64, 0, 44)
	sDesc.BackgroundTransparency = 1
	sDesc.TextColor3 = Color3.fromRGB(180, 190, 205)
	sDesc.Font = Enum.Font.Gotham
	sDesc.TextSize = 13
	sDesc.TextXAlignment = Enum.TextXAlignment.Left
	sDesc.Text = si.desc
	sDesc.ZIndex = 27
	sDesc.Parent = sRow

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 110, 0, 40)
	buyBtn.Position = UDim2.new(1, -125, 0.5, -20)
	buyBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
	buyBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 14
	buyBtn.Text = si.price
	buyBtn.ZIndex = 27
	buyBtn.Parent = sRow
	local bbC = Instance.new("UICorner"); bbC.CornerRadius = UDim.new(0, 6); bbC.Parent = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		Remotes.getEvent("BuyShopItem"):FireServer(si.id)
	end)
end

-- Sync Player Data & Purchase Result
Remotes.getEvent("PlayerDataSync").OnClientEvent:Connect(function(data: any)
	if data and data.cash then
		playerCashLabel.Text = "💰 筹码：¥ " .. RewardPool.formatNumber(data.cash)
	end
end)

Remotes.getEvent("ShopPurchaseResult").OnClientEvent:Connect(function(success: boolean, msg: string, newCash: number)
	print(string.format("[Shop] Result: %s (Cash: ¥%d)", msg, newCash))
	if success then
		playerCashLabel.Text = "💰 筹码：¥ " .. RewardPool.formatNumber(newCash)
	end
end)

-- 7. Bottom-Right Quick Action Button: [ ↖ 登台挑战 // ENTER STAGE ]
local quickEnterStageBtn = Instance.new("TextButton")
quickEnterStageBtn.Name = "QuickEnterStageButton"
quickEnterStageBtn.Size = UDim2.new(0, 200, 0, 52)
quickEnterStageBtn.Position = UDim2.new(1, -220, 1, -85)
quickEnterStageBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
quickEnterStageBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
quickEnterStageBtn.Font = Enum.Font.GothamBold
quickEnterStageBtn.TextSize = 18
quickEnterStageBtn.Text = "↖ 登台挑战"
quickEnterStageBtn.ZIndex = 15
quickEnterStageBtn.Parent = screenGui
local qesC = Instance.new("UICorner"); qesC.CornerRadius = UDim.new(0, 8); qesC.Parent = quickEnterStageBtn
local qesS = Instance.new("UIStroke"); qesS.Color = Color3.fromRGB(255, 230, 120); qesS.Thickness = 1.5; qesS.Parent = quickEnterStageBtn

-- Connecting Gazette, Sidebar & Modals
local function closeGazette()
	gazetteModal.Visible = false
	sidebarFrame.Visible = true
	quickEnterStageBtn.Visible = true
end

closeGazetteBtn.MouseButton1Click:Connect(closeGazette)
dismissGazetteBtn.MouseButton1Click:Connect(closeGazette)

btnGazette.MouseButton1Click:Connect(function()
	gazetteModal.Visible = true
end)

btnInventory.MouseButton1Click:Connect(function()
	inventoryModal.Visible = true
end)
closeInvBtn.MouseButton1Click:Connect(function()
	inventoryModal.Visible = false
end)

btnShop.MouseButton1Click:Connect(function()
	shopModal.Visible = true
end)
closeShopBtn.MouseButton1Click:Connect(function()
	shopModal.Visible = false
end)

btnSettings.MouseButton1Click:Connect(function()
	print("[Client] Settings clicked.")
end)

quickEnterStageBtn.MouseButton1Click:Connect(function()
	Remotes.getEvent("RequestStartMatch"):FireServer()
end)

-- 4. Left Reward Board
local boardFrame = Instance.new("Frame")
boardFrame.Name = "RewardBoard"
boardFrame.Size = UDim2.new(0, 220, 0, 480)
boardFrame.Position = UDim2.new(0, 20, 0.5, -220)
boardFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
boardFrame.BackgroundTransparency = 0.15
boardFrame.BorderSizePixel = 0
boardFrame.Visible = false
boardFrame.Parent = screenGui

local boardCorner = Instance.new("UICorner"); boardCorner.CornerRadius = UDim.new(0, 10); boardCorner.Parent = boardFrame
local boardStroke = Instance.new("UIStroke"); boardStroke.Color = Color3.fromRGB(245, 184, 0); boardStroke.Thickness = 1.2; boardStroke.Transparency = 0.3; boardStroke.Parent = boardFrame

local boardTitle = Instance.new("TextLabel")
boardTitle.Size = UDim2.new(1, 0, 0, 42)
boardTitle.BackgroundTransparency = 1
boardTitle.TextColor3 = Color3.fromRGB(255, 184, 0)
boardTitle.Font = Enum.Font.GothamBold
boardTitle.TextSize = 15
boardTitle.Text = "★ 奖金库档案 POOL ★"
boardTitle.Parent = boardFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = boardFrame
boardTitle.LayoutOrder = 0

local rewardLabels: { [number]: TextLabel } = {}
for idx, val in ipairs(RewardPool.VALUES) do
	local label = Instance.new("TextLabel")
	label.Name = "Val_" .. val
	label.Size = UDim2.new(1, -20, 0, 29)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundColor3 = if val >= 5000 then Color3.fromRGB(50, 40, 18) elseif val >= 1000 then Color3.fromRGB(28, 34, 46) else Color3.fromRGB(18, 22, 30)
	label.TextColor3 = if val >= 5000 then Color3.fromRGB(255, 215, 0) elseif val >= 500 then Color3.fromRGB(255, 190, 70) else Color3.fromRGB(215, 225, 240)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = "¥ " .. RewardPool.formatNumber(val)
	label.LayoutOrder = idx
	label.Parent = boardFrame

	local lblStroke = Instance.new("UIStroke")
	lblStroke.Color = if val >= 5000 then Color3.fromRGB(255, 184, 0) else Color3.fromRGB(60, 70, 88)
	lblStroke.Thickness = if val >= 5000 then 1.5 else 0.8
	lblStroke.Transparency = 0.3
	lblStroke.Parent = label

	local lblCorner = Instance.new("UICorner"); lblCorner.CornerRadius = UDim.new(0, 6); lblCorner.Parent = label
	rewardLabels[val] = label
end

-- 5. Bottom Live Stats Strip (Figure 2: 120万+ | ¥5.2亿 | 97% | 30秒)
local statsStrip = Instance.new("Frame")
statsStrip.Name = "BottomStatsStrip"
statsStrip.Size = UDim2.new(0, 680, 0, 72)
statsStrip.Position = UDim2.new(0.5, -340, 1, -86)
statsStrip.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
statsStrip.BackgroundTransparency = 0.2
statsStrip.BorderSizePixel = 0
statsStrip.Parent = screenGui

local ssCorner = Instance.new("UICorner"); ssCorner.CornerRadius = UDim.new(0, 10); ssCorner.Parent = statsStrip
local ssStroke = Instance.new("UIStroke"); ssStroke.Color = Color3.fromRGB(50, 60, 75); ssStroke.Thickness = 1; ssStroke.Parent = statsStrip

local STATS_DATA = {
	{ num = "120万+", label = "注册挑战者" },
	{ num = "¥ 5.2亿", label = "累计提现金额" },
	{ num = "97%", label = "高风险淘汰率" },
	{ num = "30秒", label = "极限决断用时" },
}

for i, data in ipairs(STATS_DATA) do
	local item = Instance.new("Frame")
	item.Size = UDim2.new(0.25, 0, 1, 0)
	item.Position = UDim2.new((i - 1) * 0.25, 0, 0, 0)
	item.BackgroundTransparency = 1
	item.Parent = statsStrip

	local numLabel = Instance.new("TextLabel")
	numLabel.Size = UDim2.new(1, 0, 0, 36)
	numLabel.Position = UDim2.new(0, 0, 0, 8)
	numLabel.BackgroundTransparency = 1
	numLabel.TextColor3 = Color3.fromRGB(245, 184, 0)
	numLabel.Font = Enum.Font.GothamBold
	numLabel.TextSize = 22
	numLabel.Text = data.num
	numLabel.Parent = item

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(1, 0, 0, 20)
	tagLabel.Position = UDim2.new(0, 0, 0, 42)
	tagLabel.BackgroundTransparency = 1
	tagLabel.TextColor3 = Color3.fromRGB(150, 160, 175)
	tagLabel.Font = Enum.Font.GothamMedium
	tagLabel.TextSize = 12
	tagLabel.Text = data.label
	tagLabel.Parent = item
end

-- 6. Leaderboard Modal Screen (User Request)
local lbModal = Instance.new("Frame")
lbModal.Name = "LeaderboardModal"
lbModal.Size = UDim2.new(0, 620, 0, 420)
lbModal.Position = UDim2.new(0.5, -310, 0.5, -210)
lbModal.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
lbModal.BorderSizePixel = 0
lbModal.Visible = false
lbModal.ZIndex = 20
lbModal.Parent = screenGui

local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0, 14); lbCorner.Parent = lbModal
local lbStroke = Instance.new("UIStroke"); lbStroke.Color = Color3.fromRGB(245, 184, 0); lbStroke.Thickness = 2; lbStroke.Parent = lbModal

local lbHeader = Instance.new("TextLabel")
lbHeader.Size = UDim2.new(1, -60, 0, 48)
lbHeader.Position = UDim2.new(0, 20, 0, 8)
lbHeader.BackgroundTransparency = 1
lbHeader.TextColor3 = Color3.fromRGB(255, 195, 25)
lbHeader.Font = Enum.Font.GothamBold
lbHeader.TextSize = 22
lbHeader.TextXAlignment = Enum.TextXAlignment.Left
lbHeader.Text = "★ 金库之夜 · 全服荣耀殿堂 ★"
lbHeader.ZIndex = 21
lbHeader.Parent = lbModal

local closeLbBtn = Instance.new("TextButton")
closeLbBtn.Size = UDim2.new(0, 32, 0, 32)
closeLbBtn.Position = UDim2.new(1, -44, 0, 16)
closeLbBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
closeLbBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
closeLbBtn.Font = Enum.Font.GothamBold
closeLbBtn.TextSize = 18
closeLbBtn.Text = "✕"
closeLbBtn.ZIndex = 22
closeLbBtn.Parent = lbModal
local clbC = Instance.new("UICorner"); clbC.CornerRadius = UDim.new(0, 6); clbC.Parent = closeLbBtn

-- Tabs (Top Earnings vs Highest Heat)
local currentTab = "EARNINGS"
local tabEarningsBtn = Instance.new("TextButton")
tabEarningsBtn.Size = UDim2.new(0, 200, 0, 34)
tabEarningsBtn.Position = UDim2.new(0, 20, 0, 58)
tabEarningsBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
tabEarningsBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
tabEarningsBtn.Font = Enum.Font.GothamBold
tabEarningsBtn.TextSize = 14
tabEarningsBtn.Text = "💰 百万金库提现榜"
tabEarningsBtn.ZIndex = 21
tabEarningsBtn.Parent = lbModal
local teC = Instance.new("UICorner"); teC.CornerRadius = UDim.new(0, 6); teC.Parent = tabEarningsBtn

local tabHeatBtn = Instance.new("TextButton")
tabHeatBtn.Size = UDim2.new(0, 200, 0, 34)
tabHeatBtn.Position = UDim2.new(0, 230, 0, 58)
tabHeatBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
tabHeatBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
tabHeatBtn.Font = Enum.Font.GothamBold
tabHeatBtn.TextSize = 14
tabHeatBtn.Text = "🔥 决断连击榜"
tabHeatBtn.ZIndex = 21
tabHeatBtn.Parent = lbModal
local thC = Instance.new("UICorner"); thC.CornerRadius = UDim.new(0, 6); thC.Parent = tabHeatBtn

local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(1, -40, 1, -112)
scrollList.Position = UDim2.new(0, 20, 0, 100)
scrollList.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
scrollList.BorderSizePixel = 0
scrollList.ScrollBarThickness = 6
scrollList.ScrollBarImageColor3 = Color3.fromRGB(245, 184, 0)
scrollList.ZIndex = 21
scrollList.Parent = lbModal
local slC = Instance.new("UICorner"); slC.CornerRadius = UDim.new(0, 8); slC.Parent = scrollList

local sLayout = Instance.new("UIListLayout")
sLayout.Padding = UDim.new(0, 6)
sLayout.SortOrder = Enum.SortOrder.LayoutOrder
sLayout.Parent = scrollList

local cachedEarningsData: { any } = {}
local cachedHeatData: { any } = {}

local function renderLeaderboardRows(dataList: { any })
	for _, child in ipairs(scrollList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	scrollList.CanvasSize = UDim2.new(0, 0, 0, #dataList * 44)

	for i, entry in ipairs(dataList) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 38)
		row.BackgroundColor3 = if i == 1 then Color3.fromRGB(45, 38, 16) elseif i % 2 == 0 then Color3.fromRGB(22, 26, 36) else Color3.fromRGB(18, 22, 30)
		row.ZIndex = 22
		row.Parent = scrollList
		local rC = Instance.new("UICorner"); rC.CornerRadius = UDim.new(0, 6); rC.Parent = row

		-- Rank
		local rankLbl = Instance.new("TextLabel")
		rankLbl.Size = UDim2.new(0, 45, 1, 0)
		rankLbl.BackgroundTransparency = 1
		rankLbl.TextColor3 = if i == 1 then Color3.fromRGB(255, 215, 0) elseif i == 2 then Color3.fromRGB(210, 225, 240) elseif i == 3 then Color3.fromRGB(205, 140, 70) else Color3.fromRGB(160, 170, 185)
		rankLbl.Font = Enum.Font.GothamBold
		rankLbl.TextSize = 16
		rankLbl.Text = "#" .. entry.rank
		rankLbl.ZIndex = 23
		rankLbl.Parent = row

		-- Player Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0, 180, 1, 0)
		nameLbl.Position = UDim2.new(0, 50, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = entry.playerName
		nameLbl.ZIndex = 23
		nameLbl.Parent = row

		-- Value (Earnings or Heat)
		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0, 160, 1, 0)
		valLbl.Position = UDim2.new(0, 240, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.TextColor3 = Color3.fromRGB(255, 205, 60)
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextSize = 14
		valLbl.Text = if currentTab == "EARNINGS" then "¥ " .. RewardPool.formatNumber(entry.earnings) else string.format("连胜 🔥 x%.1f", entry.heatMultiplier)
		valLbl.ZIndex = 23
		valLbl.Parent = row

		-- Grade / Date
		local tagLbl = Instance.new("TextLabel")
		tagLbl.Size = UDim2.new(0, 140, 1, 0)
		tagLbl.Position = UDim2.new(1, -150, 0, 0)
		tagLbl.BackgroundTransparency = 1
		tagLbl.TextColor3 = Color3.fromRGB(150, 160, 180)
		tagLbl.Font = Enum.Font.GothamMedium
		tagLbl.TextSize = 12
		tagLbl.Text = entry.grade or entry.dateStr
		tagLbl.ZIndex = 23
		tagLbl.Parent = row
	end
end

tabEarningsBtn.MouseButton1Click:Connect(function()
	currentTab = "EARNINGS"
	tabEarningsBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
	tabEarningsBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
	tabHeatBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	tabHeatBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
	renderLeaderboardRows(cachedEarningsData)
end)

tabHeatBtn.MouseButton1Click:Connect(function()
	currentTab = "HEAT"
	tabHeatBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
	tabHeatBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
	tabEarningsBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	tabEarningsBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
	renderLeaderboardRows(cachedHeatData)
end)

local function openLeaderboard()
	lbModal.Visible = true
	Remotes.getEvent("RequestLeaderboard"):FireServer()
end

closeLbBtn.MouseButton1Click:Connect(function()
	lbModal.Visible = false
end)

topLeaderboardBtn.MouseButton1Click:Connect(openLeaderboard)
lobbyLeaderboardBtn.MouseButton1Click:Connect(openLeaderboard)

Remotes.getEvent("LeaderboardData").OnClientEvent:Connect(function(topE: { any }, topH: { any })
	cachedEarningsData = topE or {}
	cachedHeatData = topH or {}
	if currentTab == "EARNINGS" then
		renderLeaderboardRows(cachedEarningsData)
	else
		renderLeaderboardRows(cachedHeatData)
	end
end)

-- 7. High-Stakes Decision HUD
local decisionFrame = Instance.new("Frame")
decisionFrame.Name = "DecisionHUD"
decisionFrame.Size = UDim2.new(0, 540, 0, 260)
decisionFrame.Position = UDim2.new(0.5, -270, 1, -280)
decisionFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
decisionFrame.BackgroundTransparency = 0.1
decisionFrame.BorderSizePixel = 0
decisionFrame.Visible = false
decisionFrame.Parent = screenGui

local decCorner = Instance.new("UICorner"); decCorner.CornerRadius = UDim.new(0, 14); decCorner.Parent = decisionFrame
local decStroke = Instance.new("UIStroke"); decStroke.Color = Color3.fromRGB(245, 184, 0); decStroke.Thickness = 1.6; decStroke.Transparency = 0.2; decStroke.Parent = decisionFrame

local offerTitle = Instance.new("TextLabel")
offerTitle.Size = UDim2.new(1, 0, 0, 28)
offerTitle.Position = UDim2.new(0, 0, 0, 12)
offerTitle.BackgroundTransparency = 1
offerTitle.TextColor3 = Color3.fromRGB(180, 190, 210)
offerTitle.Font = Enum.Font.GothamMedium
offerTitle.TextSize = 14
offerTitle.Text = "CURATOR 现金报价提议"
offerTitle.Parent = decisionFrame

local offerValueText = Instance.new("TextLabel")
offerValueText.Size = UDim2.new(1, 0, 0, 56)
offerValueText.Position = UDim2.new(0, 0, 0, 42)
offerValueText.BackgroundTransparency = 1
offerValueText.TextColor3 = Color3.fromRGB(255, 215, 0)
offerValueText.Font = Enum.Font.GothamBold
offerValueText.TextSize = 42
offerValueText.Text = "¥ 0"
offerValueText.Parent = decisionFrame

local clockBarBg = Instance.new("Frame")
clockBarBg.Size = UDim2.new(1, -60, 0, 8)
clockBarBg.Position = UDim2.new(0, 30, 0, 106)
clockBarBg.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
clockBarBg.BorderSizePixel = 0
clockBarBg.Parent = decisionFrame

local clockFill = Instance.new("Frame")
clockFill.Size = UDim2.new(1, 0, 1, 0)
clockFill.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
clockFill.BorderSizePixel = 0
clockFill.Parent = clockBarBg

local clockTimeLabel = Instance.new("TextLabel")
clockTimeLabel.Size = UDim2.new(0, 80, 0, 20)
clockTimeLabel.Position = UDim2.new(0.5, -40, 0, 118)
clockTimeLabel.BackgroundTransparency = 1
clockTimeLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
clockTimeLabel.Font = Enum.Font.GothamBold
clockTimeLabel.TextSize = 14
clockTimeLabel.Text = "18s"
clockTimeLabel.Parent = decisionFrame

local audienceSentimentLabel = Instance.new("TextLabel")
audienceSentimentLabel.Name = "AudienceSentiment"
audienceSentimentLabel.Size = UDim2.new(1, -40, 0, 20)
audienceSentimentLabel.Position = UDim2.new(0, 20, 1, -98)
audienceSentimentLabel.BackgroundTransparency = 1
audienceSentimentLabel.TextColor3 = Color3.fromRGB(255, 205, 80)
audienceSentimentLabel.Font = Enum.Font.GothamMedium
audienceSentimentLabel.TextSize = 13
audienceSentimentLabel.Text = "★ 观众公投：拿钱走人 50% | 50% 冒险翻倍"
audienceSentimentLabel.Parent = decisionFrame

local extractBtn = Instance.new("TextButton")
extractBtn.Name = "ExtractButton"
extractBtn.Size = UDim2.new(0.44, 0, 0, 54)
extractBtn.Position = UDim2.new(0.04, 0, 1, -70)
extractBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
extractBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
extractBtn.Font = Enum.Font.GothamBold
extractBtn.TextSize = 18
extractBtn.Text = "↖ 拿钱走人 (EXTRACT)"
extractBtn.Parent = decisionFrame
local extCorner = Instance.new("UICorner"); extCorner.CornerRadius = UDim.new(0, 8); extCorner.Parent = extractBtn

local pushBtn = Instance.new("TextButton")
pushBtn.Name = "PushButton"
pushBtn.Size = UDim2.new(0.44, 0, 0, 54)
pushBtn.Position = UDim2.new(0.52, 0, 1, -70)
pushBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
pushBtn.TextColor3 = Color3.fromRGB(255, 205, 75)
pushBtn.Font = Enum.Font.GothamBold
pushBtn.TextSize = 18
pushBtn.Text = "▶ 继续博弈 (PUSH)"
pushBtn.Parent = decisionFrame
local pushStroke = Instance.new("UIStroke"); pushStroke.Color = Color3.fromRGB(245, 184, 0); pushStroke.Thickness = 1.5; pushStroke.Parent = pushBtn
local pushCorner = Instance.new("UICorner"); pushCorner.CornerRadius = UDim.new(0, 8); pushCorner.Parent = pushBtn

-- 8. Spectator Voting Floating Card
local audienceVoteFrame = Instance.new("Frame")
audienceVoteFrame.Name = "AudienceVoteFrame"
audienceVoteFrame.Size = UDim2.new(0, 260, 0, 210)
audienceVoteFrame.Position = UDim2.new(1, -280, 0.5, -105)
audienceVoteFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
audienceVoteFrame.BackgroundTransparency = 0.15
audienceVoteFrame.BorderSizePixel = 0
audienceVoteFrame.Visible = false
audienceVoteFrame.Parent = screenGui

local audCorner = Instance.new("UICorner"); audCorner.CornerRadius = UDim.new(0, 12); audCorner.Parent = audienceVoteFrame
local audStroke = Instance.new("UIStroke"); audStroke.Color = Color3.fromRGB(245, 184, 0); audStroke.Thickness = 1.2; audStroke.Parent = audienceVoteFrame

local audTitle = Instance.new("TextLabel")
audTitle.Size = UDim2.new(1, 0, 0, 32)
audTitle.Position = UDim2.new(0, 0, 0, 10)
audTitle.BackgroundTransparency = 1
audTitle.TextColor3 = Color3.fromRGB(255, 184, 0)
audTitle.Font = Enum.Font.GothamBold
audTitle.TextSize = 16
audTitle.Text = "★ 观众公投投票 ★"
audTitle.Parent = audienceVoteFrame

local audSub = Instance.new("TextLabel")
audSub.Size = UDim2.new(1, 0, 0, 20)
audSub.Position = UDim2.new(0, 0, 0, 38)
audSub.BackgroundTransparency = 1
audSub.TextColor3 = Color3.fromRGB(180, 190, 205)
audSub.Font = Enum.Font.Gotham
audSub.TextSize = 12
audSub.Text = "选手是否应该见好就收？"
audSub.Parent = audienceVoteFrame

local voteExtBtn = Instance.new("TextButton")
voteExtBtn.Size = UDim2.new(0.44, 0, 0, 42)
voteExtBtn.Position = UDim2.new(0.04, 0, 0, 68)
voteExtBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
voteExtBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
voteExtBtn.Font = Enum.Font.GothamBold
voteExtBtn.TextSize = 14
voteExtBtn.Text = "↖ 走人"
voteExtBtn.Parent = audienceVoteFrame
local vExtC = Instance.new("UICorner"); vExtC.CornerRadius = UDim.new(0, 6); vExtC.Parent = voteExtBtn

local votePushBtn = Instance.new("TextButton")
votePushBtn.Size = UDim2.new(0.44, 0, 0, 42)
votePushBtn.Position = UDim2.new(0.52, 0, 0, 68)
votePushBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
votePushBtn.TextColor3 = Color3.fromRGB(245, 184, 0)
votePushBtn.Font = Enum.Font.GothamBold
votePushBtn.TextSize = 14
votePushBtn.Text = "▶ 翻倍"
votePushBtn.Parent = audienceVoteFrame
local vPushStroke = Instance.new("UIStroke"); vPushStroke.Color = Color3.fromRGB(245, 184, 0); vPushStroke.Thickness = 1.2; vPushStroke.Parent = votePushBtn
local vPushC = Instance.new("UICorner"); vPushC.CornerRadius = UDim.new(0, 6); vPushC.Parent = votePushBtn

local pollRatioLabel = Instance.new("TextLabel")
pollRatioLabel.Size = UDim2.new(1, -20, 0, 24)
pollRatioLabel.Position = UDim2.new(0, 10, 0, 122)
pollRatioLabel.BackgroundTransparency = 1
pollRatioLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
pollRatioLabel.Font = Enum.Font.GothamBold
pollRatioLabel.TextSize = 13
pollRatioLabel.Text = "走人 50% | 50% 翻倍"
pollRatioLabel.Parent = audienceVoteFrame

local ratioBarBg = Instance.new("Frame")
ratioBarBg.Size = UDim2.new(1, -30, 0, 8)
ratioBarBg.Position = UDim2.new(0, 15, 0, 154)
ratioBarBg.BackgroundColor3 = Color3.fromRGB(45, 52, 65)
ratioBarBg.BorderSizePixel = 0
ratioBarBg.Parent = audienceVoteFrame
local rbgC = Instance.new("UICorner"); rbgC.CornerRadius = UDim.new(0, 4); rbgC.Parent = ratioBarBg

local ratioExtFill = Instance.new("Frame")
ratioExtFill.Size = UDim2.new(0.5, 0, 1, 0)
ratioExtFill.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
ratioExtFill.BorderSizePixel = 0
ratioExtFill.Parent = ratioBarBg
local rFillC = Instance.new("UICorner"); rFillC.CornerRadius = UDim.new(0, 4); rFillC.Parent = ratioExtFill

-- 9. Settlement Summary Screen
local summaryFrame = Instance.new("Frame")
summaryFrame.Name = "SummaryHUD"
summaryFrame.Size = UDim2.new(0, 560, 0, 380)
summaryFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
summaryFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
summaryFrame.BorderSizePixel = 0
summaryFrame.Visible = false
summaryFrame.Parent = screenGui

local sumCorner = Instance.new("UICorner"); sumCorner.CornerRadius = UDim.new(0, 16); sumCorner.Parent = summaryFrame
local sumStroke = Instance.new("UIStroke"); sumStroke.Color = Color3.fromRGB(245, 184, 0); sumStroke.Thickness = 2; sumStroke.Parent = summaryFrame

local sumTitle = Instance.new("TextLabel")
sumTitle.Size = UDim2.new(1, 0, 0, 50)
sumTitle.Position = UDim2.new(0, 0, 0, 12)
sumTitle.BackgroundTransparency = 1
sumTitle.TextColor3 = Color3.fromRGB(245, 184, 0)
sumTitle.Font = Enum.Font.GothamBold
sumTitle.TextSize = 24
sumTitle.Text = "★ 金库之夜 · 战局结算报告 ★"
sumTitle.Parent = summaryFrame

local sumEarnedText = Instance.new("TextLabel")
sumEarnedText.Size = UDim2.new(1, 0, 0, 60)
sumEarnedText.Position = UDim2.new(0, 0, 0, 65)
sumEarnedText.BackgroundTransparency = 1
sumEarnedText.TextColor3 = Color3.fromRGB(255, 215, 0)
sumEarnedText.Font = Enum.Font.GothamBold
sumEarnedText.TextSize = 36
sumEarnedText.Text = "+ ¥ 0"
sumEarnedText.Parent = summaryFrame

local sumDetailText = Instance.new("TextLabel")
sumDetailText.Size = UDim2.new(1, -50, 0, 200)
sumDetailText.Position = UDim2.new(0, 25, 0, 135)
sumDetailText.BackgroundTransparency = 1
sumDetailText.TextColor3 = Color3.fromRGB(215, 225, 240)
sumDetailText.Font = Enum.Font.GothamMedium
sumDetailText.TextSize = 15
sumDetailText.TextXAlignment = Enum.TextXAlignment.Left
sumDetailText.TextYAlignment = Enum.TextYAlignment.Top
sumDetailText.Text = ""
sumDetailText.Parent = summaryFrame

-- 10. Start Match Action
startMatchBtn.MouseButton1Click:Connect(function()
	Remotes.getEvent("RequestStartMatch"):FireServer()
end)

extractBtn.MouseButton1Click:Connect(function()
	if extractBtn.Text:find("KEEP") or extractBtn.Text:find("保留") then
		Remotes.getEvent("FinalSwapDecision"):FireServer("KEEP")
	else
		Remotes.getEvent("PlayerDecision"):FireServer("EXTRACT")
	end
	decisionFrame.Visible = false
	statsStrip.Visible = true
end)

pushBtn.MouseButton1Click:Connect(function()
	if pushBtn.Text:find("SWAP") or pushBtn.Text:find("交换") then
		Remotes.getEvent("FinalSwapDecision"):FireServer("SWAP")
	else
		Remotes.getEvent("PlayerDecision"):FireServer("PUSH")
	end
	decisionFrame.Visible = false
	statsStrip.Visible = true
end)

voteExtBtn.MouseButton1Click:Connect(function()
	voteExtBtn.BackgroundColor3 = Color3.fromRGB(255, 184, 0)
	voteExtBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
	votePushBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	votePushBtn.TextColor3 = Color3.fromRGB(245, 184, 0)
	Remotes.getEvent("AudienceVote"):FireServer("EXTRACT")
end)

votePushBtn.MouseButton1Click:Connect(function()
	votePushBtn.BackgroundColor3 = Color3.fromRGB(245, 184, 0)
	votePushBtn.TextColor3 = Color3.fromRGB(10, 12, 16)
	voteExtBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	voteExtBtn.TextColor3 = Color3.fromRGB(245, 184, 0)
	Remotes.getEvent("AudienceVote"):FireServer("PUSH")
end)

-- 11. Network Listeners
local currentTimerThread: thread? = nil

Remotes.getEvent("StateChanged").OnClientEvent:Connect(function(newState: Types.MatchStateType, extraData: any?)
	print("[Client] State Changed to:", newState)

	if newState == MatchState.IDLE then
		AudiovisualController.exitCriticalPressure()
		sidebarFrame.Visible = true
		quickEnterStageBtn.Visible = true
		boardFrame.Visible = false
		decisionFrame.Visible = false
		summaryFrame.Visible = false
		audienceVoteFrame.Visible = false
		statsStrip.Visible = true
	elseif newState == MatchState.SELECT_CLAIM then
		AudiovisualController.exitCriticalPressure()
		gazetteModal.Visible = false
		sidebarFrame.Visible = false
		quickEnterStageBtn.Visible = false
		inventoryModal.Visible = false
		shopModal.Visible = false
		lbModal.Visible = false
		boardFrame.Visible = true
		decisionFrame.Visible = false
		summaryFrame.Visible = false
		audienceVoteFrame.Visible = false
		statsStrip.Visible = false
		extractBtn.Text = "↖ 拿钱走人 (EXTRACT)"
		pushBtn.Text = "▶ 继续博弈 (PUSH)"

		-- Reset board
		for val, lbl in pairs(rewardLabels) do
			lbl.BackgroundTransparency = 0
			lbl.TextColor3 = if val >= 5000 then Color3.fromRGB(255, 215, 0) elseif val >= 500 then Color3.fromRGB(255, 190, 70) else Color3.fromRGB(215, 225, 240)
		end
	elseif newState == MatchState.ROUND_BREACH then
		gazetteModal.Visible = false
		sidebarFrame.Visible = false
		quickEnterStageBtn.Visible = false
		boardFrame.Visible = true
		decisionFrame.Visible = false
		audienceVoteFrame.Visible = false
		statsStrip.Visible = false
	elseif newState == MatchState.PRESSURE_COUNTDOWN then
		gazetteModal.Visible = false
		sidebarFrame.Visible = false
		quickEnterStageBtn.Visible = false
		statsStrip.Visible = false
		if extraData and extraData.breakerUserId then
			if extraData.breakerUserId == localPlayer.UserId then
				decisionFrame.Visible = true
				audienceVoteFrame.Visible = false
			else
				decisionFrame.Visible = false
				audienceVoteFrame.Visible = true
				audTitle.Text = "★ 观众公投投票 ★"
				audTitle.TextColor3 = Color3.fromRGB(245, 184, 0)
				audSub.Text = "选手是否应该见好就收？"
			end
		end
	elseif newState == MatchState.FINAL_SWAP_DECISION then
		AudiovisualController.exitCriticalPressure()
		audienceVoteFrame.Visible = false
		decisionFrame.Visible = true
		statsStrip.Visible = false
		offerTitle.Text = "★ 终极命运二选一 ★"
		offerValueText.Text = "保留底牌 还是 交换最后金库？"
		extractBtn.Text = "★ 保留底牌 (KEEP)"
		pushBtn.Text = "⇄ 交换对调 (SWAP)"
	elseif newState == MatchState.FINAL_REVEAL then
		AudiovisualController.exitCriticalPressure()
		audienceVoteFrame.Visible = false
		AudiovisualController.playFinalReveal()
	elseif newState == MatchState.DECISION_EXTRACT or newState == MatchState.DECISION_PUSH then
		AudiovisualController.exitCriticalPressure()
		decisionFrame.Visible = false
		audienceVoteFrame.Visible = false
		statsStrip.Visible = false
	end
end)

Remotes.getEvent("VaultBreached").OnClientEvent:Connect(function(vaultId: number, rewardVal: number, remainingCount: number)
	local lbl = rewardLabels[rewardVal]
	if lbl then
		lbl.TextColor3 = Color3.fromRGB(80, 85, 95)
		lbl.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
		lbl.BackgroundTransparency = 0.65
	end
end)

Remotes.getEvent("OfferPresented").OnClientEvent:Connect(function(roundIdx: number, offerAmount: number, seconds: number)
	decisionFrame.Visible = true
	statsStrip.Visible = false
	extractBtn.Text = "↖ 拿钱走人 (EXTRACT)"
	pushBtn.Text = "▶ 继续博弈 (PUSH)"
	offerTitle.Text = string.format("★ 第 %d 轮 · CURATOR 现金报价 ★", roundIdx)
	offerValueText.Text = "¥ " .. RewardPool.formatNumber(offerAmount)

	if currentTimerThread then
		task.cancel(currentTimerThread)
	end

	clockFill.Size = UDim2.new(1, 0, 1, 0)
	clockFill.BackgroundColor3 = Color3.fromRGB(245, 184, 0)

	local startTime = os.clock()
	local enteredCritical = false
	currentTimerThread = task.spawn(function()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, seconds - elapsed)
			clockTimeLabel.Text = string.format("%ds", math.ceil(remaining))

			local alpha = math.clamp(remaining / seconds, 0, 1)
			clockFill.Size = UDim2.new(alpha, 0, 1, 0)

			if remaining <= 5 then
				clockFill.BackgroundColor3 = Color3.fromRGB(255, 45, 45)
				clockTimeLabel.TextColor3 = Color3.fromRGB(255, 45, 45)
				if not enteredCritical then
					enteredCritical = true
					AudiovisualController.enterCriticalPressure()
				end
			else
				clockTimeLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
			end

			if remaining <= 0 then
				break
			end
			task.wait(0.1)
		end
	end)
end)

Remotes.getEvent("AudiencePollUpdated").OnClientEvent:Connect(function(extCount: number, pushCount: number, extPct: number, pushPct: number)
	pollRatioLabel.Text = string.format("走人 %d%% | %d%% 翻倍", extPct, pushPct)
	ratioExtFill.Size = UDim2.new(extPct / 100, 0, 1, 0)
	audienceSentimentLabel.Text = string.format("★ 观众民意：走人 %d%% | %d%% 翻倍 (%d 票)", extPct, pushPct, extCount + pushCount)
end)

Remotes.getEvent("AudienceLifelineTriggered").OnClientEvent:Connect(function(seconds: number)
	audienceVoteFrame.Visible = true
	audTitle.Text = "🚨 全场紧急公投！"
	audTitle.TextColor3 = Color3.fromRGB(255, 45, 45)
	audSub.Text = string.format("选手已拉下求助操纵杆！(%ds)", seconds)

	pcall(function()
		local alertSound = Instance.new("Sound")
		alertSound.SoundId = "rbxassetid://9114227073"
		alertSound.Volume = 0.8
		alertSound.Parent = SoundService
		alertSound:Play()
	end)
end)

Remotes.getEvent("MatchEnded").OnClientEvent:Connect(function(summary: Types.MatchSummary)
	decisionFrame.Visible = false
	statsStrip.Visible = false
	summaryFrame.Visible = true

	sumEarnedText.Text = "+ ¥ " .. RewardPool.formatNumber(summary.finalEarnings)

	local evalLines = {}
	table.insert(evalLines, string.format("选手: %s | 决断连击 Heat: 🔥 x%.1f", summary.breakerName, summary.heatMultiplier))
	table.insert(evalLines, string.format("您的初始底牌金额: ¥ %s", RewardPool.formatNumber(summary.claimVaultValue)))

	if summary.finalVaultValue then
		table.insert(evalLines, string.format("场上另一只终极金库: ¥ %s", RewardPool.formatNumber(summary.finalVaultValue)))
	end

	table.insert(evalLines, "\n--- 决策品质复盘报告 (Risk-Adjusted Value) ---")
	if #summary.decisions == 0 then
		table.insert(evalLines, "未触发任何报价决策。")
	else
		for i, dec in ipairs(summary.decisions) do
			local gradeCn = if dec.grade == "ELITE_EXTRACT" then "神级提现 (ELITE)"
				elseif dec.grade == "SOUND_EXTRACT" then "稳健离场 (SOUND)"
				elseif dec.grade == "REASONABLE_PUSH" then "合理进击 (REASONABLE)"
				elseif dec.grade == "DARING_PUSH" then "勇敢博弈 (DARING)"
				elseif dec.grade == "GREEDY_BLUNDER" then "贪婪失误 (BLUNDER)"
				else "谨慎决策"
			table.insert(evalLines, string.format("决策 #%d [%s]: %s - %s", i, dec.decision, gradeCn, dec.explanation))
		end
	end

	sumDetailText.Text = table.concat(evalLines, "\n")
end)

print("[Vault Breakers] Fully Functional Lobby & Leaderboard Ready.")
