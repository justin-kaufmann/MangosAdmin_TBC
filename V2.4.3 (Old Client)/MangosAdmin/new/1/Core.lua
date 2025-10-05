-- ================= Core =================
MangosAdmin_Version = "1.0.0"

-- Public API
MangosAdmin = MangosAdmin or {}
MangosAdmin.UI = MangosAdmin.UI or {}

function SendGM(cmd)
    if cmd and cmd ~= "" then
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
MangosAdmin_GMEnabled  = MangosAdmin_GMEnabled  or false
MangosAdmin_FlyEnabled = MangosAdmin_FlyEnabled or false
MangosAdmin_Visible    = MangosAdmin_Visible    or true

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

-- Registry (Kategorien und Commands)
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
                optionsFunc = function() return MangosAdmin.GetTeleOptions() end,
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
                optionsFunc = function() return MangosAdmin.GetSpellOptions() end,
                build = function(a)
                    if a and a.value then
                        return ".cast self "..a.value
                    end
                end
            },
            {
                type = "select",
                label = "Cast Target (Dropdown)",
                optionsFunc = function() return MangosAdmin.GetSpellOptions() end,
                build = function(a)
                    if a and a.value then
                        return ".cast target "..a.value
                    end
                end
            },
            { type="input", label="Learn Spell",   inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".learn "..id end end },
            { type="input", label="Unlearn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unlearn "..id end end },
            { type="input", label="Aura",          inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".aura "..id end end },
            { type="input", label="Unaura",        inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".unaura "..id end end },
            { type="input", label="Cast Self",     inputs={{key="id",label="SpellId",width=100},{key="tr",label="triggered(opt)",width=100}}, build=function(a) local id=tonumber(a.id) if not id then return end return a.tr and (".cast self "..id.." "..a.tr) or (".cast self "..id) end },
            { type="input", label="Cooldown",      inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=tonumber(a.id) if id then return ".cooldown "..id end end },
        }
    },

    {
        category = "HP/Mana/Stats",
        commands = {
            { type="input", label="Modify HP",    inputs={{key="v",label="HP",width=100}},    build=function(a) local v=tonumber(a.v) if v then return ".modify hp "..v end end },
            { type="input", label="Modify Mana",  inputs={{key="v",label="Mana",width=100}},  build=function(a) local v=tonumber(a.v) if v then return ".modify mana "..v end end },
            { type="input", label="Modify Rage",  inputs={{key="v",label="Rage",width=100}},  build=function(a) local v=tonumber(a.v) if v then return ".modify rage "..v end end },
            { type="input", label="Modify Energy",inputs={{key="v",label="Energy",width=100}},build=function(a) local v=tonumber(a.v) if v then return ".modify energy "..v end end },
            { type="input", label="Modify TP",    inputs={{key="v",label="TP",width=100}},    build=function(a) local v=tonumber(a.v) if v then return ".modify tp "..v end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=100}}, build=function(a) local v=tonumber(a.v) if v then return ".modify scale "..v end end },
        }
    },

    {
        category = "Items & Inventar",
        commands = {
            {
                type = "select",
                label = "AddItem (Dropdown)",
                optionsFunc = function() return MangosAdmin.GetItemOptions() end,
                build = function(a)
                    if a and a.value then
                        return ".additem "..a.value.." 1"
                    end
                end
            },
            { type="input", label="AddItem",    inputs={{key="id",label="ItemId/Name",width=180},{key="c",label="Count",width=80}}, build=function(a) local c=tonumber(a.c) or 1 if a.id and a.id~="" then return ".additem "..a.id.." "..c end end },
            { type="input", label="AddItemSet", inputs={{key="id",label="ItemSetId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".additemset "..id end end },
            { type="input", label="Modify Money (Kupfer)", inputs={{key="m",label="Kupfer",width=120}}, build=function(a) local m=tonumber(a.m) if m then return ".modify money "..m end end },
            { type="button", label="Mailbox", build=function() return ".mailbox" end },
            { type="button", label="Repair Items", build=function() return ".repairitems" end },
        }
    },

    {
        category = "NPC & GO",
        commands = {
            { type="input", label="NPC Add",    inputs={{key="id",label="CreatureId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".npc add "..id end end },
            { type="input", label="NPC Delete", inputs={{key="guid",label="Guid",width=120}},      build=function(a) local g=tonumber(a.guid) if g then return ".npc delete "..g end end },
            { type="button", label="NPC Info (selected)", build=function() return ".npc info" end },
            { type="input", label="GO Add",     inputs={{key="id",label="GO Id",width=120}},       build=function(a) local id=tonumber(a.id) if id then return ".gobject add "..id end end },
            { type="input", label="GO Delete",  inputs={{key="guid",label="Guid",width=120}},      build=function(a) local g=tonumber(a.guid) if g then return ".gobject delete "..g end end },
            { type="input", label="GO Near",    inputs={{key="d",label="Dist",width=80}},          build=function(a) local d=tonumber(a.d) if d then return ".gobject near "..d end end },
        }
    },

    {
        category = "Quests & Server",
        commands = {
            {
                type = "select",
                label = "Quest Add (Dropdown)",
                optionsFunc = function() return MangosAdmin.GetQuestOptions() end,
                build = function(a)
                    if a and a.value then
                        return ".quest add "..a.value
                    end
                end
            },
            {
                type = "select",
                label = "Quest Complete (Dropdown)",
                optionsFunc = function() return MangosAdmin.GetQuestOptions() end,
                build = function(a)
                    if a and a.value then
                        return ".quest complete "..a.value
                    end
                end
            },
            { type="input", label="Quest Add",      inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest add "..id end end },
            { type="input", label="Quest Complete", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest complete "..id end end },
            { type="input", label="Quest Remove",   inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=tonumber(a.id) if id then return ".quest remove "..id end end },
            { type="button", label="Reload All",         build=function() return ".reload all" end },
            { type="button", label="Reload Config",      build=function() return ".reload config" end },
            { type="button", label="Respawn",            build=function() return ".respawn" end },
            { type="button", label="Revive",             build=function() return ".revive" end },
            { type="button", label="Server Shutdown 60s",build=function() return ".server shutdown 60" end },
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
            { type="input", label="Ticket Respond", inputs={{key="n",label="#Num",width=80},{key="msg",label="Text",width=260}}, build=function(a) if tonumber(a.n) and a.msg and a.msg~="" then return ".ticket respond "..a.n.." "..a.msg end end },
            { type="input", label="Announce", inputs={{key="m",label="Text",width=300}}, build=function(a) if a.m and a.m~="" then return ".announce "..a.m end end },
            { type="input", label="Notify",   inputs={{key="m",label="Text",width=300}}, build=function(a) if a.m and a.m~="" then return ".notify "..a.m end end },
        }
    },

    {
        category = "Lookup",
        commands = {
            { type="input", label="Lookup Item",     inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup item "..a.n end end },
            { type="input", label="Lookup Spell",    inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup spell "..a.n end end },
            { type="input", label="Lookup Creature", inputs={{key="n",label="Name",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup creature "..a.n end end },
            { type="input", label="Lookup Tele",     inputs={{key="n",label="Teilstring",width=220}}, build=function(a) if a.n and a.n~="" then return ".lookup tele "..a.n end end },
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
}