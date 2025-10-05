-- ========= Hauptfenster & Grundlayout =========
MangosAdmin = MangosAdmin or {}
MangosAdmin.UI = MangosAdmin.UI or {}

-- Hauptframe
local f = CreateFrame("Frame", "MangosAdmin_Main", UIParent)
MangosAdmin_Main = f

f:SetWidth(1000)
f:SetHeight(600)
f:SetPoint("CENTER")
f:SetBackdrop({
  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
  tile=true, tileSize=32, edgeSize=32,
  insets={left=11,right=12,top=12,bottom=11}
})
f:SetBackdropColor(0,0,0,1)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()

-- Schließen-Button
local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT")
tinsert(UISpecialFrames, f:GetName())

-- Titel
local title = f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
title:SetPoint("TOP", f, "TOP", 0, -10)
title:SetText("Mangos Admin [TBC]  —  /madmin  |  /gmraw <command>")

-- Sidebar
local sidebar = CreateFrame("Frame", nil, f)
sidebar:SetWidth(230); sidebar:SetHeight(480)
sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -44)
sidebar:SetBackdrop({
  bgFile="Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
sidebar:SetBackdropColor(0,0,0,0.5)

-- Panel rechts
local panel = CreateFrame("Frame", nil, f)
panel:SetWidth(580); panel:SetHeight(480)
panel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -44)
panel:SetBackdrop({
  bgFile="Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
panel:SetBackdropColor(0,0,0,0.35)

-- Raw Command
local rawLabel = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
rawLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 18)
rawLabel:SetText("Custom Command:")

local rawEdit = CreateFrame("EditBox", "MangosAdmin_Raw", f, "InputBoxTemplate")
rawEdit:SetWidth(640); rawEdit:SetHeight(20)
rawEdit:SetPoint("LEFT", rawLabel, "RIGHT", 10, 0)
rawEdit:SetAutoFocus(false)

local rawBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
rawBtn:SetWidth(120); rawBtn:SetHeight(22)
rawBtn:SetPoint("LEFT", rawEdit, "RIGHT", 8, 0)
rawBtn:SetText("Ausführen")
rawBtn:SetScript("OnClick", function()
  local t = rawEdit:GetText()
  if t and t ~= "" and MangosAdmin and MangosAdmin.ExecRaw then
    MangosAdmin.ExecRaw(t)
  end
end)

-- UI-Referenzen speichern
MangosAdmin.UI.frame = f
MangosAdmin.UI.sidebar = sidebar
MangosAdmin.UI.panel = panel

-- ScrollArea wird in der Init nachgeladen

-- ========== Initialisierung nach Login ==========
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
  -- ScrollArea erzeugen (muss vor Kategorien passieren)
  if MangosAdmin.CreateScrollArea then
    MangosAdmin.CreateScrollArea(panel, 10)
  end

  -- Kategorien-Buttons erzeugen
  if MangosAdmin.CreateCategoryButtons then
    MangosAdmin.CreateCategoryButtons()
  end

  -- Minimap-Button erstellen
  if MangosAdmin.CreateMinimapButton and MangosAdmin_Main then
    MangosAdmin.CreateMinimapButton(MangosAdmin_Main)
  end

  -- Status-Label
  if MangosAdmin.CreateStatusLabel then
    MangosAdmin.CreateStatusLabel(MangosAdmin_Main)
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MangosAdmin]|r UI geladen.")
end)