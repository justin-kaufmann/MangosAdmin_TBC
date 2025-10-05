-- ========= ScrollArea (ScrollFrame + Scrollbar) =========
MangosAdmin = MangosAdmin or {}
MangosAdmin.UI = MangosAdmin.UI or {}

function MangosAdmin.CreateScrollArea(panel, innerPadding)
  innerPadding = innerPadding or 10

  local scrollWidth = panel:GetWidth() - innerPadding*2 - 18
  local scrollHeight = panel:GetHeight() - innerPadding*2

  local scroll = CreateFrame("ScrollFrame", "MangosAdmin_SF", panel)
  scroll:SetWidth(scrollWidth); scroll:SetHeight(scrollHeight)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", innerPadding, -innerPadding)

  local content = CreateFrame("Frame", "MangosAdmin_Content", scroll)
  content:SetWidth(scrollWidth); content:SetHeight(scrollHeight)
  scroll:SetScrollChild(content)

  local scrollbar = CreateFrame("Slider", "MangosAdmin_ScrollBar", panel, "OptionsSliderTemplate")
  scrollbar:SetWidth(16); scrollbar:SetHeight(scrollHeight)
  scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
  scrollbar:SetMinMaxValues(0, 0)
  scrollbar:SetValueStep(10)
  _G[scrollbar:GetName().."Low"]:SetText("")
  _G[scrollbar:GetName().."High"]:SetText("")
  _G[scrollbar:GetName().."Text"]:SetText("")
  scrollbar:SetScript("OnValueChanged", function(self, val)
    scroll:SetVerticalScroll(val)
  end)

  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = scrollbar:GetValue()
    local min, max = scrollbar:GetMinMaxValues()
    cur = cur - delta*30
    if cur < min then cur = min end
    if cur > max then cur = max end
    scrollbar:SetValue(cur)
  end)

  -- Speichere im UI-Status
  MangosAdmin.UI.scroll = scroll
  MangosAdmin.UI.content = content
  MangosAdmin.UI.currentContent = content
  MangosAdmin.UI.scrollbar = scrollbar
  MangosAdmin.UI.scrollWidth = scrollWidth
  MangosAdmin.UI.scrollHeight = scrollHeight

  return scroll, content, scrollbar
end