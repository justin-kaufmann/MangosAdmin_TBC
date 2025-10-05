-- ================= Core =================
MangosAdmin_Version = "1.1"

-- Public API
MangosAdmin = {}

function SendGM(cmd)
    if cmd and cmd ~= "" then
        -- Merke manuellen Lookup-Kontext (für Parser), 5 Sekunden gültig
        --local tag = string.match(cmd, "^%.lookup%s+(item|spell|quest|tele)%s+")
		--local tag = string.match(cmd, "^%.lookup%s+(item|spell|quest|tele)%f[%a]")
		
		
		local tag = string.match(cmd, "^%.lookup%s+(%a+)")
		if tag and (tag == "item" or tag == "spell" or tag == "quest" or tag == "tele") then
			MA_LastLookupTag = tag
			MA_LastLookupExpiry = GetTime() + 5
		end

        SendChatMessage(cmd, "SAY")
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r "..cmd)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültiger/Leerer Befehl")
    end
end

-- States für Toggles
MangosAdmin_GMEnabled  = false
MangosAdmin_FlyEnabled = false
MangosAdmin_Visible    = true

function MangosAdmin.ExecRaw(text) SendGM(text) end

function MangosAdmin.ToggleGM()
    SendGM(MangosAdmin_GMEnabled and ".gm off" or ".gm on")
    MangosAdmin_GMEnabled = not MangosAdmin_GMEnabled
end

function MangosAdmin.ToggleFly()
    SendGM(MangosAdmin_FlyEnabled and ".gm fly off" or ".gm fly on")
    MangosAdmin_FlyEnabled = not MangosAdmin_FlyEnabled
    if MangosAdmin_StatusLabel then
        MangosAdmin_StatusLabel:SetText(MangosAdmin_FlyEnabled and "Fly: AN" or "Fly: AUS")
    end
end

function MangosAdmin.ToggleVisible()
    SendGM(MangosAdmin_Visible and ".gm visible off" or ".gm visible on")
    MangosAdmin_Visible = not MangosAdmin_Visible
end

local function num(v) return tonumber(v) end
local function str(v) if v and v ~= "" then return v end end

-- ================= Dynamic Lookup Indexer =================
MangosAdminDB = MangosAdminDB or { spells = {}, items = {}, quests = {}, teles = {} }

local MAX_RESULTS = 50
local MAQ = { queue = {}, running = false, cur = nil, nextAt = 0, total=0, done=0 }
local lastCount = 0

-- Kontext für manuelle Lookups (wenn kein Indexlauf aktiv)
MA_LastLookupTag = MA_LastLookupTag
MA_LastLookupExpiry = MA_LastLookupExpiry or 0

local function Enqueue(prefix, tag)
  table.insert(MAQ.queue, { prefix = prefix, tag = tag })
  MAQ.total = MAQ.total + 1
end

local function currentLookupTag()
  if MAQ.running and MAQ.cur then
    return MAQ.cur
  end
  if MA_LastLookupTag and GetTime() <= (MA_LastLookupExpiry or 0) then
    return MA_LastLookupTag
  end
  return nil
end

local function ParseLookupLine(msg)
  if not msg then return end

  -- Debug (nur wenn wir im oder nahe eines Lookup-Kontexts sind, um Spam zu reduzieren)
  local dbgTag = currentLookupTag()
  if dbgTag then
    DEFAULT_CHAT_FRAME:AddMessage(("DEBUG[%s]: "):format(dbgTag)..msg)
  end

  -- Farbcodes entfernen
  msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

  -- Aktuellen Typ bestimmen
  local tag = currentLookupTag()
  DEFAULT_CHAT_FRAME:AddMessage("TAG="..tostring(tag))
  if not tag then
    return -- unbekannter Kontext -> nicht speichern
  end

  -- Items/Spells/Quests: "1234 - Name"
  local id, name = msg:match("^(%d+)%s*%-%s*(.+)$")
  if id and name then
    local nid = tonumber(id)
    if tag == "spell" then MangosAdminDB.spells[nid] = name end
    if tag == "item"  then MangosAdminDB.items[nid]  = name end
    if tag == "quest" then MangosAdminDB.quests[nid] = name end
    lastCount = lastCount + 1
    return
  end

  -- Teleports (z. B. "Teleport location: Shattrath (shattrath)")
  local tname, key = msg:match("Teleport%s+location:%s*([^%(%-]+)%s*%(([^%)]*)%)")
  if tname and key and tag == "tele" then
    MangosAdminDB.teles[key] = tname:gsub("%s+$","")
    lastCount = lastCount + 1
  end
end

-- TBC-konformes Event-Frame
local MA_EventFrame = CreateFrame("Frame")
MA_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
MA_EventFrame:RegisterEvent("CHAT_MSG_SERVER_INFO")
MA_EventFrame:SetScript("OnEvent", function(self, event, msg)
    ParseLookupLine(msg)
end)

-- Statusanzeige (TBC-kompatibel)
local statusFrame = CreateFrame("Frame", "MA_IndexStatus", UIParent)
statusFrame:SetWidth(260); statusFrame:SetHeight(60)
statusFrame:SetPoint("CENTER")
statusFrame:SetBackdrop({
  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
statusFrame:Hide()
local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statusText:SetPoint("CENTER")

local function UpdateStatus()
  if MAQ.running then
    statusText:SetText("Indexiere "..(MAQ.cur or "?").." ("..MAQ.done.."/"..MAQ.total..")")
    statusFrame:Show()
  else
    statusFrame:Hide()
  end
end

-- Driver
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
  if GetTime() < MAQ.nextAt then return end
  if not MAQ.running then return end
  local job = table.remove(MAQ.queue, 1)
  if not job then
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Indexierung abgeschlossen: "..(MAQ.cur or ""))
    MAQ.running = false
    UpdateStatus()
    return
  end
  lastCount = 0
  -- Setze Kontext für Parser (falls Event leicht verzögert kommt)
  MA_LastLookupTag = job.tag
  MA_LastLookupExpiry = GetTime() + 5

  SendGM(".lookup "..job.tag.." "..job.prefix)
  MAQ.done = MAQ.done + 1
  UpdateStatus()
  MAQ.nextAt = GetTime() + 0.7
end)

function MangosAdmin.BuildIndex(kind)
  if MAQ.running then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffdd55[MA]|r Bereits am Indexieren …")
    return
  end
  
  -- Tabelle leeren
  if kind == "item"  then MangosAdminDB.items  = {} end
  if kind == "spell" then MangosAdminDB.spells = {} end
  if kind == "quest" then MangosAdminDB.quests = {} end
  if kind == "tele"  then MangosAdminDB.teles  = {} end
  
  MAQ.running = true
  MAQ.cur = kind
  MAQ.queue = {}
  MAQ.total, MAQ.done = 0, 0
  for c = string.byte("a"), string.byte("z") do Enqueue(string.char(c), kind) end
  for d = 0,9 do Enqueue(tostring(d), kind) end
  DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Starte Indexierung: "..kind)
  MAQ.nextAt = 0
  UpdateStatus()
end

-- Helpers für Dropdowns
local function mapToOptionsFromKV(store, makeValueText)
  local opts = {}
  for k, v in pairs(store) do
    local val, txt = makeValueText(k, v)
    table.insert(opts, { value = val, text = txt })
  end
  table.sort(opts, function(a,b) return a.text < b.text end)
  return opts
end

function MangosAdmin.GetSpellOptions()
  return mapToOptionsFromKV(MangosAdminDB.spells, function(id, name) return id, name.." ("..id..")" end)
end
--[[function MangosAdmin.GetItemOptions()
  return mapToOptionsFromKV(MangosAdminDB.items, function(id, name) return id, name.." ("..id..")" end)
end
function MangosAdmin.GetItemOptions()
  local opts = {}
  for id, name in pairs(MangosAdminDB.items) do
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel,
          itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon =
          GetItemInfo(id)

    local category = itemType or "Sonstiges"
    local sub = itemSubType or ""
    local display
    if sub ~= "" then
      display = string.format("[%s - %s] %s (%d)", category, sub, name, id)
    else
      display = string.format("[%s] %s (%d)", category, name, id)
    end

    table.insert(opts, { value = id, text = display })
  end
  table.sort(opts, function(a,b) return a.text < b.text end)
  return opts
end]]

-- ========== ItemInfo-Cache und Loader ==========
local MA_ItemCache = {}          -- [id] = {name=..., type=..., subType=..., equipLoc=...}
local MA_ItemPending = {}        -- [id] = true (wird geladen)
local MA_ItemListeners = {}      -- callbacks, wenn neue Infos da sind
local MA_ItemLoader = CreateFrame("Frame")
local MA_ItemLoader_Accum = 0

-- versteckter Tooltip zum “Anpingen” (TBC-sicher)
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
    MA_ItemCache[id] = {
      name = n, type = typeText, subType = subTypeText, equipLoc = equipLoc, icon = icon
    }
    return true
  end
  return false
end

local function MA_RequestItem(id)
  if MA_ItemCache[id] or MA_ItemPending[id] then return end
  MA_ItemPending[id] = true
  -- Tooltip anpingen triggert den Server-Request in TBC
  MA_HiddenTooltip:SetHyperlink("item:"..id)
end

-- Polling-Loader: frägt regelmäßig fehlende Items ab und befüllt den Cache
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

--[[function MangosAdmin.GetItemOptions()
  local opts = {}
  local grouped = {}

  for id, name in pairs(MangosAdminDB.items) do
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(id)
    itemType = itemType or "Sonstiges"
    itemSubType = itemSubType or "Allgemein"

    grouped[itemType] = grouped[itemType] or {}
    grouped[itemType][itemSubType] = grouped[itemType][itemSubType] or {}
    table.insert(grouped[itemType][itemSubType], { value=id, text=name, kind="item" })
  end

  for cat, subs in pairs(grouped) do
    table.insert(opts, { text=cat, kind="category" })
    for sub, items in pairs(subs) do
      table.insert(opts, { text=sub, kind="sub" })
      table.sort(items, function(a,b) return a.text < b.text end)
      for _, item in ipairs(items) do
        table.insert(opts, item)
      end
    end
  end

  return opts
end]]

function MangosAdmin.GetItemOptions()
  local opts, grouped = {}, {}

  for id, name in pairs(MangosAdminDB.items) do
    local itemName, _, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(id)

    if not itemName then
      -- Infos noch nicht da → Preload anstoßen
      MA_HiddenTooltip:SetHyperlink("item:"..id)
      itemType, itemSubType = "Sonstiges", "Allgemein"
    end

    -- Fallback: wenn kein Typ/Subtyp, aber equipLoc vorhanden
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

  -- Hierarchie aufbauen
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


function MangosAdmin.GetQuestOptions()
  return mapToOptionsFromKV(MangosAdminDB.quests, function(id, name) return id, name.." ("..id..")" end)
end
function MangosAdmin.GetTeleOptions()
  local t = {}
  for key, name in pairs(MangosAdminDB.teles) do
    table.insert(t, { value = key, text = name.." ("..key..")" })
  end
  table.sort(t, function(a,b) return a.text < b.text end)
  return t
end

-- ================= Registry aller Kategorien =================
--[[ MangosAdmin.Registry = {
    {
        category = "GM",
        commands = {
            { type="toggle", label="GM On/Off", toggle=function() MangosAdmin.ToggleGM() end },
            { type="toggle", label="GM Visible On/Off", toggle=function() MangosAdmin.ToggleVisible() end },
            { type="toggle", label="GM Fly On/Off", toggle=function() MangosAdmin.ToggleFly() end },
            { type="button", label="Save", build=function() return ".save" end },
            { type="button", label="Saveall", build=function() return ".saveall" end },
            { type="button", label="Whispers On", build=function() return ".whispers on" end },
            { type="button", label="Whispers Off", build=function() return ".whispers off" end },
            { type="button", label="GM Chat On", build=function() return ".gm chat on" end },
            { type="button", label="GM Chat Off", build=function() return ".gm chat off" end },
            { type="button", label="Server Info", build=function() return ".server info" end },
        }
    },

    {
        category = "Movement",
        commands = {
            { type="input", label="Modify Speed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify speed "..r end end },
            { type="input", label="Modify Fly", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify fly "..r end end },
            { type="input", label="Modify Swim", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify swim "..r end end },
            { type="input", label="Modify Aspeed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify aspeed "..r end end },
            { type="input", label="Modify Bwalk", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify bwalk "..r end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=80}}, build=function(a) local r=tonumber(a.v) if r then return ".modify scale "..r end end },
            { type="button", label="Dismount", build=function() return ".dismount" end },
            { type="button", label="Recall (target optional)", build=function() return ".recall" end },
        }
    },

    {
        category = "Teleport",
        commands = {
            --{
                type="select",
                label="Teleport Ort",
                optionsFunc=MangosAdmin.GetTeleOptions,
                build=function(a)
                    if a and a.value then
                        return ".tele "..a.value
                    end
                end
            },
			{
				type = "select",
				label = "Teleport",
				optionsFunc = MangosAdmin.GetTeleOptions,
				exec = function(val)
					if val then SendGM(".tele "..val) end
				end
			},

			
            {
                type="input",
                label="Go XYZ",
                inputs={
                    {key="x",label="X",width=80},
                    {key="y",label="Y",width=80},
                    {key="z",label="Z",width=80},
                    {key="map",label="Map",width=60}
                },
                build=function(a)
                    if tonumber(a.x) and tonumber(a.y) and tonumber(a.z) then
                        if tonumber(a.map) then
                            return ".go xyz "..a.x.." "..a.y.." "..a.z.." "..a.map
                        end
                        return ".go xyz "..a.x.." "..a.y.." "..a.z
                    end
                end
            },
            {
                type="input",
                label="Go Creature by id",
                inputs={{key="id",label="CreatureId",width=100}},
                build=function(a) local id=tonumber(a.id) if id then return ".go creature id "..id end end
            },
            {
                type="input",
                label="Go Object by id",
                inputs={{key="id",label="GameObjectId",width=100}},
                build=function(a) local id=tonumber(a.id) if id then return ".go object id "..id end end
            },
            {
                type="input",
                label="Go Graveyard",
                inputs={{key="id",label="GY Id",width=80}},
                build=function(a) local id=tonumber(a.id) if id then return ".go graveyard "..id end end
            },
            {
                type="button",
                label="GPS (self/target)",
                build=function() return ".gps" end
            },
        }
    },

    {
        category = "Spieler",
        commands = {
            { type="input", label="Kick", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".kick "..a.name end end },
            { type="input", label="Mute", inputs={{key="name",label="Name",width=140},{key="min",label="Min",width=60}},
              build=function(a) if a.name and a.name~="" and tonumber(a.min) then return ".mute "..a.name.." "..a.min end end },
            { type="input", label="Unmute", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unmute "..a.name end end },
            { type="input", label="Ban Account", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}},
              build=function(a) if a.name and a.name~="" and a.time and a.time~="" and a.reason and a.reason~="" then return ".ban account "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Ban Character", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}},
              build=function(a) if a.name and a.name~="" and a.time and a.time~="" and a.reason and a.reason~="" then return ".ban character "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Unban Account", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unban account "..a.name end end },
            { type="input", label="Unban Character", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unban character "..a.name end end },
            { type="input", label="PInfo", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".pinfo "..a.name end end },
        }
    },

    {
        category = "Spells & Auras",
        commands = {
			{
			type = "select",
			label = "Cast Self (Dropdown)",
			optionsFunc = MangosAdmin.GetSpellOptions,
			exec = function(val)
				if val then SendGM(".cast self "..val) end
			end
			},
			
			{
			type = "select",
			label = "Cast Target (Dropdown)",
			optionsFunc = MangosAdmin.GetSpellOptions,
			exec = function(val)
				if val then SendGM(".cast target "..val) end
			end
			},
		
            --{ type="select", label="Cast Self (Dropdown)", optionsFunc=MangosAdmin.GetSpellOptions,
              build=function(a) if a and a.value then return ".cast self "..a.value end end },

            { type="select", label="Cast Target (Dropdown)", optionsFunc=MangosAdmin.GetSpellOptions,
              build=function(a) if a and a.value then return ".cast target "..a.value end end },

            { type="input", label="Learn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".learn "..id end end },
            { type="input", label="Unlearn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unlearn "..id end end },
            { type="input", label="Aura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".aura "..id end end },
            { type="input", label="Unaura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unaura "..id end end },
            { type="input", label="Cast Self", inputs={{key="id",label="SpellId",width=100},{key="tr",label="triggered(opt)",width=100}},
              build=function(a) local id=tonumber(a.id) if not id then return end return a.tr and (".cast self "..id.." "..a.tr) or (".cast self "..id) end },
            { type="input", label="Cooldown", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".cooldown "..id end end },
        }
    },

    {
        category = "HP/Mana/Stats",
        commands = {
            { type="input", label="Modify HP", inputs={{key="v",label="HP",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify hp "..v end end },
            { type="input", label="Modify Mana", inputs={{key="v",label="Mana",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify mana "..v end end },
            { type="input", label="Modify Rage", inputs={{key="v",label="Rage",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify rage "..v end end },
            { type="input", label="Modify Energy", inputs={{key="v",label="Energy",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify energy "..v end end },
            { type="input", label="Modify TP", inputs={{key="v",label="TP",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify tp "..v end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify scale "..v end end },
        }
    },

    {
        category = "Items & Inventar",
        commands = {
            --{ type="select", label="AddItem (Dropdown)", optionsFunc=MangosAdmin.GetItemOptions,
              build=function(a) if a and a.value then return ".additem "..a.value.." 1" end end }--
			  
			{
				type = "select",
				label = "AddItem (Dropdown)",
				optionsFunc = MangosAdmin.GetItemOptions,
				exec = function(val)
					if val then
						SendGM(".additem "..val.." 1")
					end
				end
			},


            { type="input", label="AddItem", inputs={{key="id",label="ItemId/Name",width=180},{key="c",label="Count",width=80}},
              build=function(a) local c=tonumber(a.c) or 1 if a.id and a.id~="" then return ".additem "..a.id.." "..c end end },
            { type="input", label="AddItemSet", inputs={{key="id",label="ItemSetId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".additemset "..id end end },
            { type="input", label="Modify Money (Kupfer)", inputs={{key="m",label="Kupfer",width=120}}, build=function(a) local m=tonumber(a.m) if m then return ".modify money "..m end end },
            { type="button", label="Mailbox", build=function() return ".mailbox" end },
            { type="button", label="Repair Items", build=function() return ".repairitems" end },
        }
    },

    {
        category = "NPC & GO",
        commands = {
            { type="input", label="NPC Add", inputs={{key="id",label="CreatureId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".npc add "..id end end },
            { type="input", label="NPC Delete", inputs={{key="guid",label="Guid",width=120}}, build=function(a) local g=tonumber(a.guid) if g then return ".npc delete "..g end end },
            { type="button", label="NPC Info (selected)", build=function() return ".npc info" end },
            { type="input", label="GO Add", inputs={{key="id",label="GO Id",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".gobject add "..id end end },
            { type="input", label="GO Delete", inputs={{key="guid",label="Guid",width=120}}, build=function(a) local g=tonumber(a.guid) if g then return ".gobject delete "..g end end },
            { type="input", label="GO Near", inputs={{key="d",label="Dist",width=80}}, build=function(a) local d=tonumber(a.d) if d then return ".gobject near "..d end end },
        }
    },

    {
        category = "Quests & Server",
        commands = {
            --{ type="select", label="Quest Add (Dropdown)", optionsFunc=MangosAdmin.GetQuestOptions,
              build=function(a) if a and a.value then return ".quest add "..a.value end end },
            { type="select", label="Quest Complete (Dropdown)", optionsFunc=MangosAdmin.GetQuestOptions,
              build=function(a) if a and a.value then return ".quest complete "..a.value end end },
			  
			{
				type = "select",
				label = "Quest Add (Dropdown)",
				optionsFunc = MangosAdmin.GetQuestOptions,
				exec = function(val)
					if val then SendGM(".quest add "..val) end
				end
			},
			
			{
				type = "select",
				label = "Quest Complete (Dropdown)",
				optionsFunc = MangosAdmin.GetQuestOptions,
				exec = function(val)
					if val then SendGM(".quest complete "..val) end
				end
			},

            { type="input", label="Quest Add", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest add "..id end end },
            { type="input", label="Quest Complete", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest complete "..id end end },
            { type="input", label="Quest Remove", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest remove "..id end end },

            { type="button", label="Reload All", build=function() return ".reload all" end },
            { type="button", label="Reload Config", build=function() return ".reload config" end },
            { type="button", label="Respawn", build=function() return ".respawn" end },
            { type="button", label="Revive", build=function() return ".revive" end },
            { type="button", label="Server Shutdown 60s", build=function() return ".server shutdown 60" end },
            { type="button", label="Server Shutdown cancel", build=function() return ".server shutdown cancel" end },
            { type="button", label="Server Restart 60s", build=function() return ".server restart 60" end },
            { type="button", label="Server Restart cancel", build=function() return ".server restart cancel" end },
        }
    },

    {
        category = "Tickets & Notify",
        commands = {
            { type="button", label="Ticket On", build=function() return ".ticket on" end },
            { type="button", label="Ticket Off", build=function() return ".ticket off" end },
            { type="input", label="Ticket Respond", inputs={{key="n",label="#Num",width=80},{key="msg",label="Text",width=260}},
              build=function(a) if tonumber(a.n) and a.msg and a.msg~="" then return ".ticket respond "..a.n.." "..a.msg end end },
            { type="input", label="Announce", inputs={{key="m",label="Text",width=300}}, build=function(a) if a.m and a.m~="" then return ".announce "..a.m end end },
            { type="input", label="Notify", inputs={{key="m",label="Text",width=300}}, build=function(a) if a.m and a.m~="" then return ".notify "..a.m end end },
        }
    },

    {
        category = "Lookup",
        commands = {
            { type="input", label="Lookup Item", inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup item "..a.n end end },
            { type="input", label="Lookup Spell", inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup spell "..a.n end end },
            { type="input", label="Lookup Creature", inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup creature "..a.n end end },
            { type="input", label="Lookup Tele", inputs={{key="n",label="Teilstring",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup tele "..a.n end end },
        }
    },

    {
        category = "Index",
        commands = {
            { type="button", label="Build Spells Index", build=function() MangosAdmin.BuildIndex("spell"); return "" end },
            { type="button", label="Build Items Index",  build=function() MangosAdmin.BuildIndex("item");  return "" end },
            { type="button", label="Build Quests Index", build=function() MangosAdmin.BuildIndex("quest"); return "" end },
            { type="button", label="Build Tele Index",   build=function() MangosAdmin.BuildIndex("tele");  return "" end },
            { type="button", label="Build ALL Indexes", build=function()
                local order = { "spell", "item", "quest", "tele" }
                local i = 1
                local function runNext()
                    if i > #order then
                        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Alle Indexierungen abgeschlossen.")
                        return
                    end
                    local kind = order[i]
                    i = i + 1
                    MangosAdmin.BuildIndex(kind)
                    local f = CreateFrame("Frame")
                    f:SetScript("OnUpdate", function()
                        if not MAQ.running then
                            f:SetScript("OnUpdate", nil)
                            runNext()
                        end
                    end)
                end
                runNext()
                return ""
            end },
        }
    },
}]]

-- ================= Registry aller Kategorien =================
-- ================= Registry aller Kategorien =================
MangosAdmin.Registry = {
    {
        category = "GM",
        commands = {
            { type="toggle", label="GM On/Off", toggle=function() MangosAdmin.ToggleGM() end },
            { type="toggle", label="GM Visible On/Off", toggle=function() MangosAdmin.ToggleVisible() end },
            { type="toggle", label="GM Fly On/Off", toggle=function() MangosAdmin.ToggleFly() end },
            { type="button", label="Save", build=function() return ".save" end },
            { type="button", label="Saveall", build=function() return ".saveall" end },
            { type="button", label="Whispers On", build=function() return ".whispers on" end },
            { type="button", label="Whispers Off", build=function() return ".whispers off" end },
            { type="button", label="GM Chat On", build=function() return ".gm chat on" end },
            { type="button", label="GM Chat Off", build=function() return ".gm chat off" end },
            { type="button", label="Server Info", build=function() return ".server info" end },
        }
    },

    {
        category = "Movement",
        commands = {
            { type="input", label="Modify Speed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify speed "..r end end },
            { type="input", label="Modify Fly", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify fly "..r end end },
            { type="input", label="Modify Swim", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify swim "..r end end },
            { type="input", label="Modify Aspeed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify aspeed "..r end end },
            { type="input", label="Modify Bwalk", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=tonumber(a.rate) if r then return ".modify bwalk "..r end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=80}}, build=function(a) local r=tonumber(a.v) if r then return ".modify scale "..r end end },
            { type="button", label="Dismount", build=function() return ".dismount" end },
            { type="button", label="Recall (target optional)", build=function() return ".recall" end },
        }
    },

    {
        category = "Teleport",
        commands = {
            {
                type = "select",
                label = "Teleport",
                optionsFunc = MangosAdmin.GetTeleOptions,
                build = function(a)
                    if a and a.value then
                        return ".tele "..a.value
                    end
                end
            },
            {
                type="input",
                label="Go XYZ",
                inputs={
                    {key="x",label="X",width=80},
                    {key="y",label="Y",width=80},
                    {key="z",label="Z",width=80},
                    {key="map",label="Map",width=60}
                },
                build=function(a)
                    if tonumber(a.x) and tonumber(a.y) and tonumber(a.z) then
                        if tonumber(a.map) then
                            return ".go xyz "..a.x.." "..a.y.." "..a.z.." "..a.map
                        end
                        return ".go xyz "..a.x.." "..a.y.." "..a.z
                    end
                end
            },
            { type="input", label="Go Creature by id", inputs={{key="id",label="CreatureId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".go creature id "..id end end },
            { type="input", label="Go Object by id", inputs={{key="id",label="GameObjectId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".go object id "..id end end },
            { type="input", label="Go Graveyard", inputs={{key="id",label="GY Id",width=80}}, build=function(a) local id=tonumber(a.id) if id then return ".go graveyard "..id end end },
            { type="button", label="GPS (self/target)", build=function() return ".gps" end },
        }
    },

    {
        category = "Spieler",
        commands = {
            { type="input", label="Kick", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".kick "..a.name end end },
            { type="input", label="Mute", inputs={{key="name",label="Name",width=140},{key="min",label="Min",width=60}}, build=function(a) if a.name and a.name~="" and tonumber(a.min) then return ".mute "..a.name.." "..a.min end end },
            { type="input", label="Unmute", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unmute "..a.name end end },
            { type="input", label="Ban Account", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}}, build=function(a) if a.name and a.name~="" and a.time and a.time~="" and a.reason and a.reason~="" then return ".ban account "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Ban Character", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}}, build=function(a) if a.name and a.name~="" and a.time and a.time~="" and a.reason and a.reason~="" then return ".ban character "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Unban Account", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unban account "..a.name end end },
            { type="input", label="Unban Character", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".unban character "..a.name end end },
            { type="input", label="PInfo", inputs={{key="name",label="Name",width=140}}, build=function(a) if a.name and a.name~="" then return ".pinfo "..a.name end end },
        }
    },

    {
        category = "Spells & Auras",
        commands = {
            {
                type = "select",
                label = "Cast Self (Dropdown)",
                optionsFunc = MangosAdmin.GetSpellOptions,
                build = function(a)
                    if a and a.value then
                        return ".cast self "..a.value
                    end
                end
            },
            {
                type = "select",
                label = "Cast Target (Dropdown)",
                optionsFunc = MangosAdmin.GetSpellOptions,
                build = function(a)
                    if a and a.value then
                        return ".cast target "..a.value
                    end
                end
            },
            { type="input", label="Learn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".learn "..id end end },
            { type="input", label="Unlearn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unlearn "..id end end },
            { type="input", label="Aura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".aura "..id end end },
            { type="input", label="Unaura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unaura "..id end end },
            { type="input", label="Cast Self", inputs={{key="id",label="SpellId",width=100},{key="tr",label="triggered(opt)",width=100}}, build=function(a) local id=tonumber(a.id) if not id then return end return a.tr and (".cast self "..id.." "..a.tr) or (".cast self "..id) end },
            {type="input", label="Cooldown", inputs={{key="id",label="SpellId",width=100}},
              build=function(a)
                  local id=tonumber(a.id)
                  if id then return ".cooldown "..id end
              end
            },
        }
	},
    

    {
        category = "HP/Mana/Stats",
        commands = {
            { type="input", label="Modify HP", inputs={{key="v",label="HP",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify hp "..v end end },
            { type="input", label="Modify Mana", inputs={{key="v",label="Mana",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify mana "..v end end },
            { type="input", label="Modify Rage", inputs={{key="v",label="Rage",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify rage "..v end end },
            { type="input", label="Modify Energy", inputs={{key="v",label="Energy",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify energy "..v end end },
            { type="input", label="Modify TP", inputs={{key="v",label="TP",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify tp "..v end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=100}},
              build=function(a) local v=tonumber(a.v) if v then return ".modify scale "..v end end },
        }
    },

    {
        category = "Items & Inventar",
        commands = {
            {
                type = "select",
                label = "AddItem (Dropdown)",
                optionsFunc = MangosAdmin.GetItemOptions,
                build = function(a)
                    if a and a.value then
                        return ".additem "..a.value.." 1"
                    end
                end
            },
            { type="input", label="AddItem", inputs={{key="id",label="ItemId/Name",width=180},{key="c",label="Count",width=80}},
              build=function(a) local c=tonumber(a.c) or 1 if a.id and a.id~="" then return ".additem "..a.id.." "..c end end },
            { type="input", label="AddItemSet", inputs={{key="id",label="ItemSetId",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".additemset "..id end end },
            { type="input", label="Modify Money (Kupfer)", inputs={{key="m",label="Kupfer",width=120}},
              build=function(a) local m=tonumber(a.m) if m then return ".modify money "..m end end },
            { type="button", label="Mailbox", build=function() return ".mailbox" end },
            { type="button", label="Repair Items", build=function() return ".repairitems" end },
        }
    },

    {
        category = "NPC & GO",
        commands = {
            { type="input", label="NPC Add", inputs={{key="id",label="CreatureId",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".npc add "..id end end },
            { type="input", label="NPC Delete", inputs={{key="guid",label="Guid",width=120}},
              build=function(a) local g=tonumber(a.guid) if g then return ".npc delete "..g end end },
            { type="button", label="NPC Info (selected)", build=function() return ".npc info" end },
            { type="input", label="GO Add", inputs={{key="id",label="GO Id",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".gobject add "..id end end },
            { type="input", label="GO Delete", inputs={{key="guid",label="Guid",width=120}},
              build=function(a) local g=tonumber(a.guid) if g then return ".gobject delete "..g end end },
            { type="input", label="GO Near", inputs={{key="d",label="Dist",width=80}},
              build=function(a) local d=tonumber(a.d) if d then return ".gobject near "..d end end },
        }
    },

    {
        category = "Quests & Server",
        commands = {
            {
                type = "select",
                label = "Quest Add (Dropdown)",
                optionsFunc = MangosAdmin.GetQuestOptions,
                build = function(a)
                    if a and a.value then
                        return ".quest add "..a.value
                    end
                end
            },
            {
                type = "select",
                label = "Quest Complete (Dropdown)",
                optionsFunc = MangosAdmin.GetQuestOptions,
                build = function(a)
                    if a and a.value then
                        return ".quest complete "..a.value
                    end
                end
            },
            { type="input", label="Quest Add", inputs={{key="id",label="QuestId",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".quest add "..id end end },
            { type="input", label="Quest Complete", inputs={{key="id",label="QuestId",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".quest complete "..id end end },
            { type="input", label="Quest Remove", inputs={{key="id",label="QuestId",width=120}},
              build=function(a) local id=tonumber(a.id) if id then return ".quest remove "..id end end },
            { type="button", label="Reload All", build=function() return ".reload all" end },
            { type="button", label="Reload Config", build=function() return ".reload config" end },
            { type="button", label="Respawn", build=function() return ".respawn" end },
            { type="button", label="Revive", build=function() return ".revive" end },
            { type="button", label="Server Shutdown 60s", build=function() return ".server shutdown 60" end },
            { type="button", label="Server Shutdown cancel", build=function() return ".server shutdown cancel" end },
            { type="button", label="Server Restart 60s", build=function() return ".server restart 60" end },
            { type="button", label="Server Restart cancel", build=function() return ".server restart cancel" end },
        }
    },

    {
        category = "Tickets & Notify",
        commands = {
            { type="button", label="Ticket On", build=function() return ".ticket on" end },
            { type="button", label="Ticket Off", build=function() return ".ticket off" end },
            { type="input", label="Ticket Respond", inputs={{key="n",label="#Num",width=80},{key="msg",label="Text",width=260}},
              build=function(a) if tonumber(a.n) and a.msg and a.msg~="" then return ".ticket respond "..a.n.." "..a.msg end end },
            { type="input", label="Announce", inputs={{key="m",label="Text",width=300}},
              build=function(a) if a.m and a.m~="" then return ".announce "..a.m end end },
            { type="input", label="Notify", inputs={{key="m",label="Text",width=300}},
              build=function(a) if a.m and a.m~="" then return ".notify "..a.m end end },
        }
    },

    {
        category = "Lookup",
        commands = {
            { type="input", label="Lookup Item", inputs={{key="n",label="Name",width=220}},
              build=function(a) if a.n and a.n~="" then return ".lookup item "..a.n end end },
            { type="input", label="Lookup Spell", inputs={{key="n",label="Name",width=220}},
              build=function(a) if a.n and a.n~="" then return ".lookup spell "..a.n end end },
            { type="input", label="Lookup Creature", inputs={{key="n",label="Name",width=220}},
              build=function(a) if a.n and a.n~="" then return ".lookup creature "..a.n end end },
            { type="input", label="Lookup Tele", inputs={{key="n",label="Teilstring",width=220}},
              build=function(a) if a.n and a.n~="" then return ".lookup tele "..a.n end end },
        }
    },
	
	{
        category = "Index",
        commands = {
            { type="button", label="Build Spells Index", build=function() MangosAdmin.BuildIndex("spell"); return "" end },
            { type="button", label="Build Items Index",  build=function() MangosAdmin.BuildIndex("item");  return "" end },
            { type="button", label="Build Quests Index", build=function() MangosAdmin.BuildIndex("quest"); return "" end },
            { type="button", label="Build Tele Index",   build=function() MangosAdmin.BuildIndex("tele");  return "" end },
            { type="button", label="Build ALL Indexes", build=function()
                local order = { "spell", "item", "quest", "tele" }
                local i = 1
                local function runNext()
                    if i > #order then
                        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Alle Indexierungen abgeschlossen.")
                        return
                    end
                    local kind = order[i]
                    i = i + 1
                    MangosAdmin.BuildIndex(kind)
                    -- Warte bis dieser Index fertig ist, dann starte den nächsten
                    local f = CreateFrame("Frame")
                    f:SetScript("OnUpdate", function()
                        if not MAQ.running then
                            f:SetScript("OnUpdate", nil)
                            runNext()
                        end
                    end)
                end
                runNext()
                return ""
            end },
        }
    },
}

-- ================= Slash =================
SLASH_MANGOSADMIN1 = "/madmin"
SlashCmdList["MANGOSADMIN"] = function()
    if MangosAdmin_Main and MangosAdmin_Main:IsShown() then
        MangosAdmin_Main:Hide()
    else
        if MangosAdmin_Main then MangosAdmin_Main:Show() end
    end
end

SLASH_GMRAW1 = "/gmraw"
SlashCmdList["GMRAW"] = function(msg)
    if msg and msg ~= "" then
        MangosAdmin.ExecRaw(msg)
    end
end
