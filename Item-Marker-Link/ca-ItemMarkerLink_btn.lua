-- ca-ItemMarkerLink_btn.lua
-- Toolbar-Button für ItemMarkerLink.
--
-- Click       → Skript starten (falls nicht läuft) / Fenster öffnen-schließen
-- Alt+Click   → Sync An/Aus
-- Shift+Click → Skript stoppen
--
-- LED leuchtet wenn Skript läuft UND Sync aktiv.

local EXT = "ItemMarkerLink"

-- Eigene ID ermitteln und persistent speichern
local _, _, sectionID, cmdID = reaper.get_action_context()
cmdID = tonumber(cmdID)
if cmdID and cmdID ~= 0 then
  reaper.SetExtState(EXT, "btn_cmd_id", tostring(cmdID), true)
end

local running  = reaper.GetExtState(EXT, "running") == "1"
local sync_on  = reaper.GetExtState(EXT, "sync_state") == "1"

-- LED: leuchtet wenn läuft und Sync an
if cmdID and cmdID ~= 0 then
  reaper.SetToggleCommandState(sectionID, cmdID, (running and sync_on) and 1 or 0)
  reaper.RefreshToolbar2(sectionID, cmdID)
end

-- Modifier-Tasten
local shift = reaper.JS_Mouse_GetState and (reaper.JS_Mouse_GetState(8)  & 8)  == 8  or false
local alt   = reaper.JS_Mouse_GetState and (reaper.JS_Mouse_GetState(16) & 16) == 16 or false

if not running then
  if shift then return end  -- Shift+Click wenn nicht läuft: nichts tun
  -- Skript starten
  local info     = debug.getinfo(1, "S")
  local this_dir = info.source:match("@(.*[/\\])")
  local main_path = this_dir .. "ca-ItemMarkerLink.lua"
  if reaper.file_exists(main_path) then
    local main_id = reaper.AddRemoveReaScript(true, 0, main_path, true)
    if main_id and main_id ~= 0 then
      reaper.Main_OnCommand(main_id, 0)
    end
  else
    reaper.ShowMessageBox(
      "ca-ItemMarkerLink.lua nicht gefunden in:\n" .. (this_dir or "?"),
      "ItemMarkerLink", 0)
  end
  return
end

-- Skript läuft → Befehl senden
if shift then
  reaper.SetExtState(EXT, "cmd", "stop", false)
elseif alt then
  reaper.SetExtState(EXT, "cmd", "toggle_sync", false)
  -- LED optimistisch invertieren
  if cmdID and cmdID ~= 0 then
    reaper.SetToggleCommandState(sectionID, cmdID, sync_on and 0 or 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
  end
else
  reaper.SetExtState(EXT, "cmd", "show", false)
end
