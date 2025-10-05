-- ========== ItemInfo-Cache, Loader & Item-Dropdown-Optionen ==========
MangosAdmin = MangosAdmin or {}

local MA_ItemCache = {}
local MA_ItemPending = {}
local MA_ItemListeners = {}
local MA_ItemLoader = CreateFrame("Frame")
local MA_ItemLoader_Accum = 0

if not MA_HiddenTooltip then
  MA_HiddenTooltip = CreateFrame("GameTooltip", "MA_HiddenTooltip", UIParent, "GameTooltipTemplate")
  MA_HiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
end

local function MA_NotifyItemListeners()
  for cb in pairs(MA_ItemListeners) do
    local ok = pcall(cb)
  end
end

function MangosAdmin.RegisterItemInfoListener(func)
  if type(func) == "function" then
    MA_ItemListeners[func] = true
  end
end
function MangosAdmin.UnregisterItemInfoListener(func)
  MA_ItemListeners[func] = nil
end

local function MA_TryFillCache(id)
  if MA_ItemCache[id] then return true end
  local n, link, r, ilvl, min, typeText, subTypeText, stack, equipLoc, icon = GetItemInfo(id)
  if n then
    MA_ItemCache[id] = { name = n, type = typeText, subType = subTypeText, equipLoc = equipLoc, icon = icon }
    return true
  end
  return false
end

local function MA_RequestItem(id)
  if MA_ItemCache[id] or MA_ItemPending[id] then return end
  MA_ItemPending[id] = true
  MA_HiddenTooltip:SetHyperlink("item:"..id)
end

MA_ItemLoader:SetScript("OnUpdate", function(self, elapsed)
  if not next(MA_ItemPending) then return end
  MA_ItemLoader_Accum = MA_ItemLoader_Accum + elapsed
  if MA_ItemLoader_Accum < 0.25 then return end
  MA_ItemLoader_Accum = 0

  local updated = false
  for id in pairs(MA_ItemPending) do
    if MA_TryFillCache(id) then
      MA_ItemPending[id] = nil
      updated = true
    end
  end
  if updated then
    MA_NotifyItemListeners()
  end
end)

function MangosAdmin.GetItemOptions()
  local opts, grouped = {}, {}

  for id, name in pairs(MangosAdminDB.items or {}) do
    local itemName, _, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(id)

    if not itemName then
      MA_HiddenTooltip:SetHyperlink("item:"..id)
      itemType, itemSubType = "Sonstiges", "Allgemein"
    end

    if not itemType and equipLoc and equipLoc ~= "" then
      if equipLoc:find("WEAPON") then
        itemType = "Waffe"
      else
        itemType = "Rüstung"
      end
      itemSubType = "Unbekannt"
    end

    itemType    = itemType    or "Sonstiges"
    itemSubType = itemSubType or "Allgemein"

    grouped[itemType] = grouped[itemType] or {}
    grouped[itemType][itemSubType] = grouped[itemType][itemSubType] or {}
    table.insert(grouped[itemType][itemSubType], { value=id, text=(itemName or name).." ("..id..")", kind="item" })
  end

  local catNames = {}
  for cat in pairs(grouped) do table.insert(catNames, cat) end
  table.sort(catNames)

  for _, cat in ipairs(catNames) do
    table.insert(opts, { text=cat, kind="category" })
    local subs = grouped[cat]
    local subNames = {}
    for sub in pairs(subs) do table.insert(subNames, sub) end
    table.sort(subNames)
    for _, sub in ipairs(subNames) do
      table.insert(opts, { text=sub, kind="sub" })
      table.sort(subs[sub], function(a,b) return a.text < b.text end)
      for _, it in ipairs(subs[sub]) do
        table.insert(opts, it)
      end
    end
  end

  return opts
end