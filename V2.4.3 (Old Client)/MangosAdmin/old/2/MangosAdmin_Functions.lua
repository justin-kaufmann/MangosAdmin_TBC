-- ================= Core =================
MangosAdmin_Version = "1.0"

local function SendGM(cmd)
    if cmd and cmd ~= "" then
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

-- Public API
MangosAdmin = {}

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

-- ================= Teleport-Liste (deutsch) =================
-- Du kannst die Liste beliebig erweitern.
MangosAdmin.TeleList = {
    { text="Sturmwind", value="stormwind" },
    { text="Eisenschmiede", value="ironforge" },
    { text="Darnassus", value="darnassus" },
    { text="Orgrimmar", value="orgrimmar" },
    { text="Donnerfels", value="thunderbluff" },
    { text="Unterstadt", value="undercity" },

    { text="Shattrath", value="shattrath" },
    { text="Höllenfeuerhalbinsel - Ehrenfeste", value="honorhold" },
    { text="Höllenfeuerhalbinsel - Thrallmar", value="thrallmar" },
    { text="Zangarmarschen - Zabra'jin", value="zabrajin" },
    { text="Zangarmarschen - Telredor", value="telredor" },
    { text="Nagrand - Garadar", value="garadar" },
    { text="Nagrand - Telaar", value="telaar" },
    { text="Schergrat - Sylvanaar", value="sylvanaar" },
    { text="Schergrat - Mok'Nathal", value="moknathal" },
    { text="Nethersturm - Area 52", value="area52" },
    { text="Schattenmondtal - Wildhammerfeste", value="wildhammer" },
    { text="Schattenmondtal - Schattenmond", value="shadowmoon" },
    { text="Terokkar - Allerias Feste", value="alleriaposten" },
    { text="Terokkar - Steinard", value="stonebreakerhold" },

    { text="Düstermarschen - Theramore", value="theramore" },
    { text="Tirisfal - Brill", value="brill" },
    { text="Westfall - Späherkuppe", value="sentinelhill" },
    { text="Rotkammgebirge - Seenhain", value="lakeshire" },
    { text="Ashenvale - Astranaar", value="astranaar" },
    { text="Brachland - Crossroads", value="thecrossroads" },
    { text="Hügel des Klingenhügels - Klingenhügel", value="razorhill" },
    { text="Geisterlande - Tristessa", value="tranquillien" },

    { text="Karazhan", value="karazhan" },
    { text="Zul'Gurub", value="zul'gurub" },
    { text="Geschmolzener Kern", value="molten core" },
    { text="Pechschwingenhort", value="blackwing lair" },
    { text="Zul'Aman", value="zul'aman" },
    { text="Gruuls Unterschlupf", value="gruul's lair" },
    { text="Magtheridons Kammer", value="magtheridon's lair" },
    { text="Höhle des Schlangenschreins", value="serpentshrine cavern" },
    { text="Festung der Stürme", value="tempest keep" },
    { text="Schwarzer Tempel", value="black temple" },
    { text="Sonnenbrunnenplateau", value="sunwell plateau" }
}

-- ================= Registry aller Kategorien =================
-- Typen:
--  type="toggle"  -> ein Button, ruft cmd.toggle() auf
--  type="input"   -> Eingabefelder (inputs = { {key, label, width}... }), build(args) -> ".cmd ..."
--  type="select"  -> Dropdown (options = {...}), build({value=<selected>})
--  type="button"  -> einfacher Run-Button mit fixem build()

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
            { type="input", label="Modify Speed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=num(a.rate) if r then return ".modify speed "..r end end },
            { type="input", label="Modify Fly", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=num(a.rate) if r then return ".modify fly "..r end end },
            { type="input", label="Modify Swim", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=num(a.rate) if r then return ".modify swim "..r end end },
            { type="input", label="Modify Aspeed", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=num(a.rate) if r then return ".modify aspeed "..r end end },
            { type="input", label="Modify Bwalk", inputs={{key="rate",label="Rate",width=80}}, build=function(a) local r=num(a.rate) if r then return ".modify bwalk "..r end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=80}}, build=function(a) local r=num(a.v) if r then return ".modify scale "..r end end },
            { type="button", label="Dismount", build=function() return ".dismount" end },
            { type="button", label="Recall (target optional)", build=function() return ".recall" end },
        }
    },

	{
		category = "Teleport",
		commands = {
			{
				type="select",
				label="Teleport Ort",
				options=MangosAdmin.TeleList,  -- deine deutsche Liste
				build=function(a)
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
            { type="input", label="Kick", inputs={{key="name",label="Name",width=140}}, build=function(a) if str(a.name) then return ".kick "..a.name end end },
            { type="input", label="Mute", inputs={{key="name",label="Name",width=140},{key="min",label="Min",width=60}},
              build=function(a) if str(a.name) and num(a.min) then return ".mute "..a.name.." "..a.min end end },
            { type="input", label="Unmute", inputs={{key="name",label="Name",width=140}}, build=function(a) if str(a.name) then return ".unmute "..a.name end end },
            { type="input", label="Ban Account", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}},
              build=function(a) if str(a.name) and str(a.time) and str(a.reason) then return ".ban account "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Ban Character", inputs={{key="name",label="Name",width=120},{key="time",label="Zeit",width=80},{key="reason",label="Grund",width=160}},
              build=function(a) if str(a.name) and str(a.time) and str(a.reason) then return ".ban character "..a.name.." "..a.time.." "..a.reason end end },
            { type="input", label="Unban Account", inputs={{key="name",label="Name",width=140}}, build=function(a) if str(a.name) then return ".unban account "..a.name end end },
            { type="input", label="Unban Character", inputs={{key="name",label="Name",width=140}}, build=function(a) if str(a.name) then return ".unban character "..a.name end end },
            { type="input", label="PInfo", inputs={{key="name",label="Name",width=140}}, build=function(a) if str(a.name) then return ".pinfo "..a.name end end },
        }
    },

    {
        category = "Spells & Auras",
        commands = {
            { type="input", label="Learn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=num(a.id) if id then return ".learn "..id end end },
            { type="input", label="Unlearn Spell", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=num(a.id) if id then return ".unlearn "..id end end },
            { type="input", label="Aura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=num(a.id) if id then return ".aura "..id end end },
            { type="input", label="Unaura", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=num(a.id) if id then return ".unaura "..id end end },
            { type="input", label="Cast Self", inputs={{key="id",label="SpellId",width=100},{key="tr",label="triggered(opt)",width=100}},
              build=function(a) local id=num(a.id) if not id then return end return a.tr and (".cast self "..id.." "..a.tr) or (".cast self "..id) end },
            { type="input", label="Cooldown", inputs={{key="id",label="SpellId",width=100}}, build=function(a) local id=num(a.id) if id then return ".cooldown "..id end end },
        }
    },

    {
        category = "HP/Mana/Stats",
        commands = {
            { type="input", label="Modify HP", inputs={{key="v",label="HP",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify hp "..v end end },
            { type="input", label="Modify Mana", inputs={{key="v",label="Mana",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify mana "..v end end },
            { type="input", label="Modify Rage", inputs={{key="v",label="Rage",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify rage "..v end end },
            { type="input", label="Modify Energy", inputs={{key="v",label="Energy",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify energy "..v end end },
            { type="input", label="Modify TP", inputs={{key="v",label="TP",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify tp "..v end end },
            { type="input", label="Modify Scale", inputs={{key="v",label="Scale",width=100}}, build=function(a) local v=num(a.v) if v then return ".modify scale "..v end end },
        }
    },

    {
        category = "Items & Inventar",
        commands = {
            { type="input", label="AddItem", inputs={{key="id",label="ItemId/Name",width=180},{key="c",label="Count",width=80}},
              build=function(a) local c=num(a.c) or 1 if str(a.id) then return ".additem "..a.id.." "..c end end },
            { type="input", label="AddItemSet", inputs={{key="id",label="ItemSetId",width=120}}, build=function(a) local id=num(a.id) if id then return ".additemset "..id end end },
            { type="input", label="Modify Money (Kupfer)", inputs={{key="m",label="Kupfer",width=120}}, build=function(a) local m=num(a.m) if m then return ".modify money "..m end end },
            { type="button", label="Mailbox", build=function() return ".mailbox" end },
            { type="button", label="Repair Items", build=function() return ".repairitems" end },
        }
    },

    {
        category = "NPC & GO",
        commands = {
            { type="input", label="NPC Add", inputs={{key="id",label="CreatureId",width=120}}, build=function(a) local id=num(a.id) if id then return ".npc add "..id end end },
            { type="input", label="NPC Delete", inputs={{key="guid",label="Guid",width=120}}, build=function(a) local g=num(a.guid) if g then return ".npc delete "..g end end },
            { type="button", label="NPC Info (selected)", build=function() return ".npc info" end },
            { type="input", label="GO Add", inputs={{key="id",label="GO Id",width=120}}, build=function(a) local id=num(a.id) if id then return ".gobject add "..id end end },
            { type="input", label="GO Delete", inputs={{key="guid",label="Guid",width=120}}, build=function(a) local g=num(a.guid) if g then return ".gobject delete "..g end end },
            { type="input", label="GO Near", inputs={{key="d",label="Dist",width=80}}, build=function(a) local d=num(a.d) if d then return ".gobject near "..d end end },
        }
    },

    {
        category = "Quests & Server",
        commands = {
            { type="input", label="Quest Add", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=num(a.id) if id then return ".quest add "..id end end },
            { type="input", label="Quest Complete", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=num(a.id) if id then return ".quest complete "..id end end },
            { type="input", label="Quest Remove", inputs={{key="id",label="QuestId",width=120}}, build=function(a) local id=num(a.id) if id then return ".quest remove "..id end end },

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
              build=function(a) if num(a.n) and str(a.msg) then return ".ticket respond "..a.n.." "..a.msg end end },
            { type="input", label="Announce", inputs={{key="m",label="Text",width=300}}, build=function(a) if str(a.m) then return ".announce "..a.m end end },
            { type="input", label="Notify", inputs={{key="m",label="Text",width=300}}, build=function(a) if str(a.m) then return ".notify "..a.m end end },
        }
    },

    {
        category = "Lookup",
        commands = {
            { type="input", label="Lookup Item", inputs={{key="n",label="Name",width=220}}, build=function(a) if str(a.n) then return ".lookup item "..a.n end end },
            { type="input", label="Lookup Spell", inputs={{key="n",label="Name",width=220}}, build=function(a) if str(a.n) then return ".lookup spell "..a.n end end },
            { type="input", label="Lookup Creature", inputs={{key="n",label="Name",width=220}}, build=function(a) if str(a.n) then return ".lookup creature "..a.n end end },
            { type="input", label="Lookup Tele", inputs={{key="n",label="Teilstring",width=220}}, build=function(a) if str(a.n) then return ".lookup tele "..a.n end end },
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
SlashCmdList["GMRAW"] = function(msg) if msg and msg ~= "" then MangosAdmin.ExecRaw(msg) end end
