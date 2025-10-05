-- ================= Dynamic Lookup Indexer & Parser =================

-- SavedVariables-Strukturen sicherstellen (defensiv)
MangosAdminDB = MangosAdminDB or {}
MangosAdminDB.spells       = MangosAdminDB.spells       or {}
MangosAdminDB.items        = MangosAdminDB.items        or {}
MangosAdminDB.itemsets     = MangosAdminDB.itemsets     or {}
MangosAdminDB.itemsetItems = MangosAdminDB.itemsetItems or {}
MangosAdminDB.quests       = MangosAdminDB.quests       or {}
MangosAdminDB.teles        = MangosAdminDB.teles        or {}
MangosAdminDB.areas        = MangosAdminDB.areas        or {}
MangosAdminDB.skills       = MangosAdminDB.skills       or {}
MangosAdminDB.titles       = MangosAdminDB.titles       or {}
MangosAdminDB.taxinodes    = MangosAdminDB.taxinodes    or {}
MangosAdminDB.objects      = MangosAdminDB.objects      or {}

-- Gemeinsamer MAQ-State aus Core.lua
MangosAdmin = MangosAdmin or {}
MangosAdmin.MAQ = MangosAdmin.MAQ or { queue = {}, running = false, cur = nil, nextAt = 0, total = 0, done = 0 }

-- Optional: konfigurierbares Throttling
MangosAdmin.LookupThrottle = MangosAdmin.LookupThrottle or 0.7

-- Konsistentes LastLookup-Tracking (gemeinsam mit Core.lua)
MangosAdmin.LastLookup = MangosAdmin.LastLookup or { tag = nil, expiry = 0 }

-- Enqueue (Fallback, falls nicht in Core.lua definiert)
if not MangosAdmin.Enqueue then
  function MangosAdmin.Enqueue(prefix, kind)
    table.insert(MangosAdmin.MAQ.queue, { prefix = prefix, kind = kind })
    MangosAdmin.MAQ.total = (MangosAdmin.MAQ.total or 0) + 1
  end
end
local Enqueue = MangosAdmin.Enqueue

-- Aktuelles Lookup-Tag bestimmen
local function currentLookupTag()
  if MangosAdmin.MAQ.running and MangosAdmin.MAQ.cur then
    return MangosAdmin.MAQ.cur
  end
  local ll = MangosAdmin.LastLookup
  if ll and ll.tag and GetTime() <= (ll.expiry or 0) then
    return ll.tag
  end
  return nil
end

-- Zeilenparser für .lookup Ausgaben
local function ParseLookupLine(msg)
  if not msg then return end

  -- Farbe entfernen
  msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

  local tag = currentLookupTag()
  if not tag then return end

  -- Standardformat: "12345 - Name"
  local id, name = msg:match("^(%d+)%s*%-%s*(.+)$")
  if id and name then
    local nid = tonumber(id)
    if nid then
      if tag == "spell"    then MangosAdminDB.spells[nid]    = name end
      if tag == "item"     then MangosAdminDB.items[nid]     = name end
      if tag == "itemset"  then
        -- Nur Set-ID und Name speichern; Items werden später via Lazy-Build ermittelt
        MangosAdminDB.itemsets[nid] = name
      end
      if tag == "quest"    then MangosAdminDB.quests[nid]    = name end
      if tag == "area"     then MangosAdminDB.areas[nid]     = name end
      if tag == "skill"    then MangosAdminDB.skills[nid]    = name end
      if tag == "object"   then MangosAdminDB.objects[nid]   = name end
      if tag == "taxinode" then MangosAdminDB.taxinodes[nid] = name end
      if tag == "title"    then MangosAdminDB.titles[nid]    = name end
    end
    return
  end

  -- Titel-Sonderformat: "ID {idx: x} - Name"
  local tid, idx, tname = msg:match("^(%d+)%s*{idx:%s*(%d+)}%s*%-%s*(.+)$")
  if tid and tname and tag == "title" then
    MangosAdminDB.titles[tonumber(tid)] = tname
    return
  end

  -- Taxinode-Sonderformat: "ID - Name (Map: ...)"
  local xid, xname = msg:match("^(%d+)%s*%-%s*([^%(]+)")
  if xid and xname and tag == "taxinode" then
    MangosAdminDB.taxinodes[tonumber(xid)] = xname:gsub("%s+$","")
    return
  end

  -- Teleport: nur Name
  if tag == "tele" then
    local tname = msg:match("^(.+)$")
    if tname then
      MangosAdminDB.teles[tname:lower()] = tname
    end
  end
end

-- Event-Listener: Systemnachrichten parsen
local MA_EventFrame = CreateFrame("Frame")
MA_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
MA_EventFrame:SetScript("OnEvent", function(self, event, msg)
  ParseLookupLine(msg)
end)

-- Driver für asynchrone Abarbeitung der Queue
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
  if GetTime() < (MangosAdmin.MAQ.nextAt or 0) then return end
  if not MangosAdmin.MAQ.running then return end

  local job = table.remove(MangosAdmin.MAQ.queue, 1)
  if not job then
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Indexierung abgeschlossen: "..(MangosAdmin.MAQ.cur or ""))
    end
    MangosAdmin.MAQ.running = false
    if type(UpdateStatus) == "function" then UpdateStatus() end
    return
  end

  -- Letztes Lookup-Tag setzen (für Parser)
  MangosAdmin.LastLookup.tag = job.kind
  MangosAdmin.LastLookup.expiry = GetTime() + 5

  -- Befehl senden und Fortschritt aktualisieren
  SendGM(".lookup "..job.kind.." "..job.prefix)
  MangosAdmin.MAQ.done = (MangosAdmin.MAQ.done or 0) + 1

  if type(UpdateStatus) == "function" then UpdateStatus() end

  -- Throttle
  MangosAdmin.MAQ.nextAt = GetTime() + (MangosAdmin.LookupThrottle or 0.7)
end)

-- KEINE BuildIndex-Redefinition hier: Core.lua enthält die kanonische Version.

-- Optionen für Dropdowns (generische Helfer)
local function mapToOptionsFromKV(store, makeValueText)
  local opts = {}
  if not store then return opts end
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

function MangosAdmin.GetQuestOptions()
  return mapToOptionsFromKV(MangosAdminDB.quests, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetAreaOptions()
  return mapToOptionsFromKV(MangosAdminDB.areas, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetSkillOptions()
  return mapToOptionsFromKV(MangosAdminDB.skills, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetTitleOptions()
  return mapToOptionsFromKV(MangosAdminDB.titles, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetTaxinodeOptions()
  return mapToOptionsFromKV(MangosAdminDB.taxinodes, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetObjectOptions()
  return mapToOptionsFromKV(MangosAdminDB.objects, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetTeleOptions()
  local t = {}
  for key, name in pairs(MangosAdminDB.teles) do
    table.insert(t, { value = key, text = name })
  end
  table.sort(t, function(a,b) return a.text < b.text end)
  return t
end

-- Itemset-Optionen mit Lazy-Build
function MangosAdmin.SetItemsetItems(setId, itemIds)
  MangosAdminDB.itemsetItems[setId] = itemIds or {}
end

function MangosAdmin.GetItemsetOptions()
    local opts = {}

    -- Stelle sicher, dass die Itemset-Items überhaupt gebaut wurden
    if not MangosAdminDB.itemsetItems or not next(MangosAdminDB.itemsetItems) then
        if MangosAdmin and MangosAdmin.BuildItemsetIndexAuto then
            MangosAdmin.BuildItemsetIndexAuto()
        end
    end

    if MangosAdminDB and MangosAdminDB.itemsets then
        for id, name in pairs(MangosAdminDB.itemsets) do
            -- Hole die Items für dieses Set, oder setze eine leere Tabelle als Fallback
            local items = (MangosAdminDB.itemsetItems and MangosAdminDB.itemsetItems[id]) or {}

            table.insert(opts, {
                value = id,
                text  = name .. " (" .. id .. ")",
                kind  = "itemset",
                items = items
            })
        end
    end

    -- Sortiere alphabetisch nach Text für Übersichtlichkeit
    table.sort(opts, function(a, b)
        return a.text < b.text
    end)

    return opts
end

