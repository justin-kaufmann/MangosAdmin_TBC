-- ========= GuiMinimapButton.lua =========
MangosAdmin = MangosAdmin or {}

if not MangosAdminDB then MangosAdminDB = {} end
if not MangosAdminDB.minimapAngle then MangosAdminDB.minimapAngle = 45 end

function MangosAdmin.CreateMinimapButton(mainFrame)
  local btn = CreateFrame("Button", "MangosAdmin_MinimapButton", Minimap)
  btn:SetWidth(32)
  btn:SetHeight(32)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = btn:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("CENTER")

  local function UpdateButtonPos()
    local angle = MangosAdminDB.minimapAngle or 45
    local rad = math.rad(angle)
    local radius = (Minimap:GetWidth()/2) - 5
    local x = cos(rad) * radius
    local y = sin(rad) * radius
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end

  UpdateButtonPos()

  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = GetCursorPosition()
      local cx, cy = Minimap:GetCenter()
      local scale = Minimap:GetEffectiveScale()
      mx, my = mx/scale, my/scale
      MangosAdminDB.minimapAngle = math.deg(math.atan2(my - cy, mx - cx))
      UpdateButtonPos()
    end)
  end)
  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  btn:SetScript("OnClick", function()
    if mainFrame:IsShown() then
      mainFrame:Hide()
    else
      mainFrame:Show()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("MangosAdmin")
    GameTooltip:AddLine("Linksklick: Fenster öffnen/schließen", 1, 1, 1)
    GameTooltip:AddLine("Ziehen: Symbol verschieben", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return btn
end