-- DK Skellies - Monitora pets via BossFrame (polling OnUpdate)

-- Verifica se o personagem é Death Knight
local _, playerClass = UnitClass("player")
if playerClass ~= "DEATHKNIGHT" then
  DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DKSkellies]|r Inactive — Death Knight required.")
  return
end

local MAX_BOSSES       = 6
local BAR_WIDTH        = 160
local BAR_HEIGHT       = 16
local POWER_HEIGHT     = 6
local PAD              = 1
local TITLE_HEIGHT     = 20
local MEMBER_HEIGHT    = BAR_HEIGHT + POWER_HEIGHT + PAD * 3
local CONTAINER_HEIGHT = TITLE_HEIGHT + MAX_BOSSES * MEMBER_HEIGHT
local UPDATE_THROTTLE  = 0.1
local DEBUG            = false

-- SavedVariables
DKSkelliesDB           = DKSkelliesDB or { scale = 1.0, hideBossFrames = true }

local function SetBossTargetFrames(hidden)
  for i = 1, MAX_BOSSES do
    local frame = _G["Boss" .. i .. "TargetFrame"]
    if frame then
      if hidden then frame:Hide() else frame:Show() end
    end
  end
end

local function log(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DKSkellies]|r " .. tostring(msg))
end

-- Container principal
local container = CreateFrame("Frame", "DKSkelliesContainer", UIParent)
container:SetWidth(BAR_WIDTH + 8)
container:SetHeight(CONTAINER_HEIGHT)
container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
container:SetFrameStrata("LOW")
container:SetMovable(true)
container:Hide()

-- Barra de título (arrastável)
local titleBar = CreateFrame("Button", nil, container)
titleBar:SetWidth(BAR_WIDTH - 8)
titleBar:SetHeight(TITLE_HEIGHT)
titleBar:SetPoint("TOP", container, "TOP", 0, 0)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 0, 0)
titleText:SetText("DKSkellies")
titleText:SetTextColor(1, 0.3, 0.3, 1)

titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() container:StartMoving() end)
titleBar:SetScript("OnDragStop", function() container:StopMovingOrSizing() end)

-- Cria os membros
local members = {}

for i = 1, MAX_BOSSES do
  local btn = CreateFrame("Button", "DKSkelliesMember" .. i, container, "SecureActionButtonTemplate")
  btn:SetWidth(BAR_WIDTH)
  btn:SetHeight(MEMBER_HEIGHT)
  btn:SetPoint("TOP", container, "TOP", 0, -TITLE_HEIGHT - ((i - 1) * MEMBER_HEIGHT))

  btn:SetAttribute("type", "target")
  btn:SetAttribute("unit", "boss" .. i)

  btn.index = i
  btn.unit = "boss" .. i

  -- Fundo
  btn:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  -- Highlight
  btn:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
  local hl = btn:GetHighlightTexture()
  hl:SetAllPoints()
  hl:SetBlendMode("ADD")

  -- Barra de vida
  btn.health = CreateFrame("StatusBar", nil, btn)
  btn.health:SetWidth(BAR_WIDTH - 8)
  btn.health:SetHeight(BAR_HEIGHT)
  btn.health:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, -2)
  btn.health:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
  btn.health:SetMinMaxValues(0, 1)
  btn.health:SetValue(1)

  btn.health.bg = btn.health:CreateTexture(nil, "BACKGROUND")
  btn.health.bg:SetAllPoints()
  btn.health.bg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
  btn.health.bg:SetVertexColor(0.2, 0.2, 0.2, 1)

  btn.nameText = btn.health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.nameText:SetPoint("LEFT", btn.health, "LEFT", 4, 0)
  btn.nameText:SetText("")
  btn.nameText:SetJustifyH("LEFT")

  btn.pctText = btn.health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.pctText:SetPoint("RIGHT", btn.health, "RIGHT", -4, 0)
  btn.pctText:SetText("")
  btn.pctText:SetJustifyH("RIGHT")

  -- Barra de recurso
  btn.power = CreateFrame("StatusBar", nil, btn)
  btn.power:SetWidth(BAR_WIDTH - 8)
  btn.power:SetHeight(POWER_HEIGHT)
  btn.power:SetPoint("TOPLEFT", btn.health, "BOTTOMLEFT", 0, -PAD)
  btn.power:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
  btn.power:SetMinMaxValues(0, 1)
  btn.power:SetValue(1)

  btn.power.bg = btn.power:CreateTexture(nil, "BACKGROUND")
  btn.power.bg:SetAllPoints()
  btn.power.bg:SetTexture("Interface/TargetingFrame/UI-StatusBar")
  btn.power.bg:SetVertexColor(0.1, 0.1, 0.15, 1)

  btn:Hide()
  members[i] = btn
end

-- Atualiza um botão
local function UpdateMember(btn)
  local unit = btn.unit
  if not unit or not UnitExists(unit) then
    if btn:IsShown() then
      btn:Hide()
      if DEBUG then log("hide " .. unit) end
    end
    return
  end

  if not btn:IsShown() then
    btn:Show()
    if DEBUG then log("show " .. unit .. " (" .. (UnitName(unit) or "") .. ")") end
  end

  local name = UnitName(unit)
  btn.nameText:SetText(name or "")

  local hp = UnitHealth(unit)
  local hpMax = UnitHealthMax(unit)
  if hpMax and hpMax > 0 then
    btn.health:SetMinMaxValues(0, hpMax)
    btn.health:SetValue(hp)
    local pct = hp / hpMax
    btn.pctText:SetText(string.format("%d%%", pct * 100))
    if pct > 0.5 then
      btn.health:SetStatusBarColor((1 - pct) * 2, 1, 0)
    else
      btn.health:SetStatusBarColor(1, pct * 2, 0)
    end
  end

  local powerType = UnitPowerType(unit)
  local power = UnitPower(unit)
  local powerMax = UnitPowerMax(unit)
  if powerMax and powerMax > 0 then
    btn.power:SetMinMaxValues(0, powerMax)
    btn.power:SetValue(power)
  else
    btn.power:SetMinMaxValues(0, 1)
    btn.power:SetValue(0)
  end

  if powerType == 0 then
    btn.power:SetStatusBarColor(0.2, 0.4, 1)
  elseif powerType == 1 then
    btn.power:SetStatusBarColor(1, 0, 0)
  elseif powerType == 3 then
    btn.power:SetStatusBarColor(1, 0.9, 0.2)
  elseif powerType == 6 then
    btn.power:SetStatusBarColor(0, 0.8, 0.8)
  else
    btn.power:SetStatusBarColor(0.5, 0.5, 0.5)
  end
end

local function UpdateContainerVisibility()
  local hasVisible = false
  for _, btn in ipairs(members) do
    if btn:IsShown() then
      hasVisible = true
      break
    end
  end
  if hasVisible then
    container:Show()
  else
    container:Hide()
  end
end

local function UpdateAll()
  for _, btn in ipairs(members) do
    UpdateMember(btn)
  end
  UpdateContainerVisibility()
  if DKSkelliesDB.hideBossFrames then
    SetBossTargetFrames(true)
  end
end

-- Driver OnUpdate
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(self, e)
  self.elapsed = (self.elapsed or 0) + e
  if self.elapsed >= UPDATE_THROTTLE then
    self.elapsed = 0
    UpdateAll()
  end
end)

driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_ENTERING_WORLD" then
    if DEBUG then log("PLAYER_ENTERING_WORLD") end
    self.elapsed = UPDATE_THROTTLE
    SetBossTargetFrames(DKSkelliesDB.hideBossFrames)
    UpdateAll()
  end
end)

-- Comando unificado /dksk (ou /dkskellies)
local function HandleCommand(msg)
  local cmd, arg = strsplit(" ", msg or "", 2)
  cmd = (cmd or ""):lower()

  if cmd == "debug" then
    DEBUG = not DEBUG
    log("Debug " .. (DEBUG and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
  elseif cmd == "scale" then
    local s = tonumber(arg)
    if s and s >= 0.3 and s <= 3.0 then
      DKSkelliesDB.scale = s
      container:SetScale(s)
      log("Scale set to " .. string.format("%.1f", s))
    else
      log("Usage: /dksk scale <0.3..3.0> | Current: " .. string.format("%.1f", DKSkelliesDB.scale))
    end
  elseif cmd == "bossframes" then
    DKSkelliesDB.hideBossFrames = not DKSkelliesDB.hideBossFrames
    SetBossTargetFrames(DKSkelliesDB.hideBossFrames)
    log("Boss target frames " .. (DKSkelliesDB.hideBossFrames and "|cFFFF0000hidden|r" or "|cFF00FF00shown|r"))
  elseif cmd == "reset" then
    DEBUG = false
    DKSkelliesDB.scale = 1.0
    DKSkelliesDB.hideBossFrames = true
    container:SetScale(1.0)
    SetBossTargetFrames(true)
    log("Settings restored to default |cFF00FF00(debug=off, scale=1.0, bossframes=hidden)|r")
  elseif cmd == "help" or cmd == "" then
    log("|cFFFFFF00/dksk commands:|r")
    log("  |cFFAAAAAAdebug|r  - toggle debug log (" .. (DEBUG and "ON" or "OFF") .. ")")
    log("  |cFFAAAAAAscale <n>|r - set scale (0.3 to 3.0, current " .. string.format("%.1f", DKSkelliesDB.scale) .. ")")
    log("  |cFFAAAAAAbossframes|r - toggle Blizzard boss target frames (" ..
      (DKSkelliesDB.hideBossFrames and "hidden" or "shown") .. ")")
    log("  |cFFAAAAAAreset|r  - restore defaults")
    log("  |cFFAAAAAAhelp|r   - this message")
  else
    log("Unknown command: " .. cmd .. ". Use |cFFFFFF00/dksk help|r")
  end
end

SLASH_DKSKELLIES1 = "/dksk"
SLASH_DKSKELLIES2 = "/dkskellies"
SlashCmdList["DKSKELLIES"] = HandleCommand

-- Aplicar configurações salvas
container:SetScale(DKSkelliesDB.scale)
SetBossTargetFrames(DKSkelliesDB.hideBossFrames)

UpdateAll()
log("Loaded |cFFFFFF00[scale " ..
  string.format("%.1f", DKSkelliesDB.scale) ..
  " bossframes " .. (DKSkelliesDB.hideBossFrames and "hidden" or "shown") .. "]|r /dksk help")
