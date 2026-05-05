-- ca-ItemMarkerLink.lua
-- Hauptskript – läuft im Hintergrund.
-- NICHT in die Toolbar legen – dafür ca-ItemMarkerLink_btn.lua verwenden.

local EXT            = "ItemMarkerLink"
local COUPLED_PREFIX = "§"

local links            = {}
local prevMarkerPos    = {}
local prevItemPos      = {}
local manual_decoupled = {}

local sync_active        = true
local auto_couple_active = true
local gui_visible        = true
local gui_w, gui_h       = 440, 360
local prev_mouse_cap     = 0

local _, _, sectionID, cmdID = reaper.get_action_context()
cmdID = tonumber(cmdID)

-- ============================================================
-- TOOLBAR
-- ============================================================
local function update_toolbar()
  local running = reaper.GetExtState(EXT, "running") == "1"
  local state   = (running and sync_active) and 1 or 0
  reaper.SetExtState(EXT, "sync_state", sync_active and "1" or "0", false)
  -- Btn-Skript-ID persistent gespeichert vom Btn-Skript selbst
  local btn_id = tonumber(reaper.GetExtState(EXT, "btn_cmd_id"))
  if btn_id and btn_id ~= 0 then
    reaper.SetToggleCommandState(1, btn_id, state)
    reaper.RefreshToolbar2(1, btn_id)
  end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function get_item_guid(item)
  if not reaper.ValidatePtr(item, "MediaItem*") then return nil end
  return reaper.BR_GetMediaItemGUID(item)
end

local function find_item_by_guid(guid)
  for t = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, t)
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
      local item = reaper.GetTrackMediaItem(track, i)
      if reaper.BR_GetMediaItemGUID(item) == guid then return item end
    end
  end
  return nil
end

local function get_item_position(item)
  return reaper.GetMediaItemInfo_Value(item, "D_POSITION")
end

local function set_item_position(item, pos)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  reaper.UpdateItemInProject(item)
end

local function get_all_markers()
  local t = {}
  for i = 0, reaper.CountProjectMarkers(0) - 1 do
    local ok, isrgn, pos, _, name, mid = reaper.EnumProjectMarkers(i)
    if ok and not isrgn then table.insert(t, {id=mid, pos=pos, name=name}) end
  end
  return t
end

local function get_coupled_markers()
  local t = {}
  for _, m in ipairs(get_all_markers()) do
    if m.name:sub(1, #COUPLED_PREFIX) == COUPLED_PREFIX then table.insert(t, m) end
  end
  return t
end

local function find_nearest_item(pos, tol)
  local best, bestD = nil, math.huge
  for t2 = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, t2)
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
      local item = reaper.GetTrackMediaItem(track, i)
      local d = math.abs(get_item_position(item) - pos)
      if d < bestD then bestD = d; best = item end
    end
  end
  return bestD <= tol and best or nil
end

local function set_marker_position(mid, newPos)
  for i = 0, reaper.CountProjectMarkers(0) - 1 do
    local ok, isrgn, _, _, name, id = reaper.EnumProjectMarkers(i)
    if ok and not isrgn and id == mid then
      reaper.SetProjectMarker(mid, false, newPos, 0, name); return true
    end
  end
end

local function get_marker_pos(mid)
  for i = 0, reaper.CountProjectMarkers(0) - 1 do
    local ok, isrgn, pos, _, _, id = reaper.EnumProjectMarkers(i)
    if ok and not isrgn and id == mid then return pos end
  end
end

-- ============================================================
-- KOPPLUNG
-- ============================================================
local function couple_marker(mid, mpos, item)
  local guid = get_item_guid(item); if not guid then return false end
  local ipos = get_item_position(item)
  links[mid]            = {item_guid=guid, offset=mpos-ipos}
  prevMarkerPos[mid]    = mpos
  prevItemPos[guid]     = ipos
  manual_decoupled[mid] = nil
  return true
end

local function decouple_marker(mid, manual)
  if links[mid] then
    local guid = links[mid].item_guid
    links[mid] = nil; prevMarkerPos[mid] = nil
    local used = false
    for _, v in pairs(links) do if v.item_guid == guid then used=true; break end end
    if not used then prevItemPos[guid] = nil end
  end
  if manual then manual_decoupled[mid] = true end
end

local function auto_couple_once()
  for _, m in ipairs(get_coupled_markers()) do
    if not links[m.id] and not manual_decoupled[m.id] then
      local item = find_nearest_item(m.pos, 0.5)
      if item then couple_marker(m.id, m.pos, item) end
    end
  end
end

-- ============================================================
-- SYNC
-- ============================================================
local function sync()
  if not sync_active then return end
  local valid = {}
  for _, m in ipairs(get_all_markers()) do valid[m.id] = true end
  local rem = {}
  for id in pairs(links) do if not valid[id] then table.insert(rem, id) end end
  for _, id in ipairs(rem) do decouple_marker(id, false) end
  if auto_couple_active then auto_couple_once() end
  for mid, link in pairs(links) do
    local item = find_item_by_guid(link.item_guid)
    if not item then decouple_marker(mid, false)
    else
      local curMP = get_marker_pos(mid)
      local curIP = get_item_position(item)
      if not curMP then decouple_marker(mid, false)
      else
        local prevMP = prevMarkerPos[mid]
        local prevIP = prevItemPos[link.item_guid]
        if prevMP and prevIP then
          local mMoved = math.abs(curMP-prevMP) > 0.0001
          local iMoved = math.abs(curIP-prevIP) > 0.0001
          if mMoved and not iMoved then
            local newIP = curMP - link.offset
            reaper.Undo_BeginBlock()
            set_item_position(item, newIP)
            reaper.Undo_EndBlock("ItemMarkerLink: Item folgt Marker", -1)
            prevItemPos[link.item_guid] = newIP; prevMarkerPos[mid] = curMP
          elseif iMoved and not mMoved then
            local newMP = curIP + link.offset
            reaper.Undo_BeginBlock()
            set_marker_position(mid, newMP)
            reaper.Undo_EndBlock("ItemMarkerLink: Marker folgt Item", -1)
            prevMarkerPos[mid] = newMP; prevItemPos[link.item_guid] = curIP
          else
            prevMarkerPos[mid] = curMP; prevItemPos[link.item_guid] = curIP
          end
        else
          prevMarkerPos[mid] = curMP; prevItemPos[link.item_guid] = curIP
        end
      end
    end
  end
  reaper.UpdateArrange()
end

-- ============================================================
-- IPC
-- ============================================================
local function check_ipc()
  local cmd = reaper.GetExtState(EXT, "cmd")
  if cmd == "" then return end
  reaper.SetExtState(EXT, "cmd", "", false)
  if cmd == "show" then
    if gui_visible then
      gfx.quit(); gui_visible = false
    else
      gfx.init("ItemMarkerLink", gui_w, gui_h, 0, 200, 150)
      gfx.setfont(1, "Consolas", 13)
      gui_visible = true
    end
  elseif cmd == "toggle_sync" then
    sync_active = not sync_active
    update_toolbar()
  elseif cmd == "stop" then
    reaper.atexit(function() end)  -- atexit überschreiben damit update_toolbar noch läuft
    -- Toolbar auf grau setzen
    local btn_id = tonumber(reaper.GetExtState(EXT, "btn_cmd_id"))
    if btn_id and btn_id ~= 0 then
      reaper.SetToggleCommandState(1, btn_id, 0)
      reaper.RefreshToolbar2(1, btn_id)
    end
    reaper.SetExtState(EXT, "running", "0", true)
    if gui_visible then gfx.quit() end
    -- Loop nicht mehr weiterführen: defer wird nicht nochmal aufgerufen
    -- (wir setzen eine Flag)
    _G._iml_stop = true
  end
end

-- ============================================================
-- GUI
-- ============================================================
local function draw_button(label, x, y, w, h, r, g, b, rh, gh, bh, clicked)
  local hover = gfx.mouse_x>=x and gfx.mouse_x<=x+w and
                gfx.mouse_y>=y and gfx.mouse_y<=y+h
  gfx.set(hover and rh or r, hover and gh or g, hover and bh or b, 1)
  gfx.rect(x, y, w, h, true)
  gfx.set((hover and rh or r)+0.12,(hover and gh or g)+0.12,(hover and bh or b)+0.12,1)
  gfx.rect(x, y, w, h, false)
  gfx.setfont(1, "Consolas", 13)
  local sw, sh = gfx.measurestr(label)
  gfx.set(0.94, 0.97, 1.0, 1)
  gfx.x = x+math.floor((w-sw)/2); gfx.y = y+math.floor((h-sh)/2)
  gfx.drawstr(label)
  return hover and clicked
end

local function gui_tick()
  local W, H   = gui_w, gui_h
  local cur_mc = gfx.mouse_cap
  local clicked = (cur_mc&1==1) and (prev_mouse_cap&1==0)
  prev_mouse_cap = cur_mc

  gfx.set(0.10,0.10,0.18,1); gfx.rect(0,0,W,H,true)
  gfx.set(0.12,0.12,0.22,1); gfx.rect(0,0,W,30,true)
  gfx.setfont(1,"Consolas",13)
  gfx.set(0.65,0.80,1.0,1); gfx.x,gfx.y=10,8
  gfx.drawstr("ItemMarkerLink")
  gfx.set(0.40,0.50,0.70,1)
  local hint='Prefix: "'..COUPLED_PREFIX..'"'
  gfx.x,gfx.y=W-gfx.measurestr(hint)-10,8; gfx.drawstr(hint)

  local sl=sync_active and "  ● SYNC AN  " or "  ○ SYNC AUS"
  local sr,sg,sb   =sync_active and 0.10 or 0.30,sync_active and 0.40 or 0.10,sync_active and 0.16 or 0.10
  local srh,sgh,sbh=sync_active and 0.14 or 0.44,sync_active and 0.56 or 0.14,sync_active and 0.22 or 0.14
  if draw_button(sl,10,36,W-20,30,sr,sg,sb,srh,sgh,sbh,clicked) then
    sync_active=not sync_active; update_toolbar()
  end

  gfx.set(0.20,0.20,0.32,1); gfx.line(0,74,W,74)

  local y=80
  local coupled=get_coupled_markers()
  gfx.setfont(1,"Consolas",12)
  if #coupled==0 then
    gfx.set(0.40,0.40,0.58,1); gfx.x,gfx.y=10,y
    gfx.drawstr('Keine §-Marker. Umbenennen zu "§Name".')
  end
  for _,m in ipairs(coupled) do
    local link=links[m.id]; local linked=link~=nil
    gfx.set(linked and 0.11 or 0.15,linked and 0.19 or 0.11,linked and 0.13 or 0.12,1)
    gfx.rect(4,y,W-8,24,true)
    gfx.set(linked and 0.20 or 0.60,linked and 0.80 or 0.25,linked and 0.30 or 0.25,1)
    gfx.x,gfx.y=10,y+6; gfx.drawstr(linked and "●" or "○")
    gfx.set(0.88,0.93,1.0,1); gfx.x,gfx.y=26,y+6
    local ns=m.name
    while gfx.measurestr(ns)>115 and #ns>1 do ns=ns:sub(1,-2) end
    if ns~=m.name then ns=ns.."…" end
    gfx.drawstr(ns)
    local st="nicht gekoppelt"
    if linked then
      local item=find_item_by_guid(link.item_guid)
      if item then
        local take=reaper.GetActiveTake(item)
        local n2=take and reaper.GetTakeName(take) or "(kein Take)"
        local n2o=n2
        while gfx.measurestr(n2)>155 and #n2>1 do n2=n2:sub(1,-2) end
        if n2~=n2o then n2=n2.."…" end
        st="→ "..n2
      else st="⚠ Item gelöscht" end
    end
    gfx.set(linked and 0.40 or 0.52,linked and 0.85 or 0.40,linked and 0.52 or 0.40,1)
    gfx.x,gfx.y=150,y+6; gfx.drawstr(st)
    local bl=linked and "Entkoppeln" or "Koppeln"
    local br,bg2,bb  =linked and 0.28 or 0.14,linked and 0.13 or 0.26,linked and 0.13 or 0.18
    local brh,bgh,bbh=linked and 0.46 or 0.18,linked and 0.17 or 0.40,linked and 0.17 or 0.26
    if draw_button(bl,W-94,y+2,86,20,br,bg2,bb,brh,bgh,bbh,clicked) then
      if linked then decouple_marker(m.id,true)
      else
        local item=find_nearest_item(m.pos,2.0)
        if item then couple_marker(m.id,m.pos,item)
        else reaper.ShowMessageBox(
          'Kein Item nahe "'..m.name..'" (±2s).', "ItemMarkerLink",0) end
      end
    end
    y=y+28
    if y>H-78 then
      gfx.set(0.40,0.40,0.58,1); gfx.x,gfx.y=10,y
      gfx.drawstr("… (Fenster vergrößern für weitere Marker)"); break
    end
  end

  gfx.set(0.20,0.20,0.32,1); gfx.line(0,H-56,W,H-56)
  local nlinks=0; for _ in pairs(links) do nlinks=nlinks+1 end
  gfx.setfont(1,"Consolas",11); gfx.set(0.40,0.45,0.62,1)
  gfx.x,gfx.y=10,H-48
  gfx.drawstr(("Aktiv: %d  |  §-Marker: %d  |  Sync: %s"):format(
    nlinks,#coupled,sync_active and "AN" or "AUS"))

  local al=auto_couple_active and "Auto-koppeln: AN" or "Auto-koppeln: AUS"
  local ar,ag,ab   =auto_couple_active and 0.13 or 0.22,auto_couple_active and 0.28 or 0.14,auto_couple_active and 0.42 or 0.14
  local arh,agh,abh=auto_couple_active and 0.17 or 0.34,auto_couple_active and 0.40 or 0.20,auto_couple_active and 0.58 or 0.20
  if draw_button(al,10,H-30,152,22,ar,ag,ab,arh,agh,abh,clicked) then
    auto_couple_active=not auto_couple_active
    if auto_couple_active then manual_decoupled={}; auto_couple_once() end
  end
  if draw_button("Alle entkoppeln",W-128,H-30,118,22,
      0.30,0.11,0.11,0.48,0.15,0.15,clicked) then
    local ids={}; for id in pairs(links) do table.insert(ids,id) end
    for _,id in ipairs(ids) do decouple_marker(id,true) end
  end
  gfx.update()
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function main()
  if _G._iml_stop then return end  -- stop-Befehl empfangen
  reaper.SetExtState(EXT, "running", "1", true)
  check_ipc()
  if _G._iml_stop then return end
  sync()
  if gui_visible then
    gui_tick()
    if gfx.getchar()==-1 then gfx.quit(); gui_visible=false end
  end
  reaper.defer(main)
end

-- ============================================================
-- START
-- ============================================================
_G._iml_stop = false
reaper.SetExtState(EXT, "running",    "1", true)
reaper.SetExtState(EXT, "cmd",        "",  false)
reaper.SetExtState(EXT, "sync_state", "1", false)

gfx.init("ItemMarkerLink", gui_w, gui_h, 0, 200, 150)
gfx.setfont(1, "Consolas", 13)
update_toolbar()
auto_couple_once()
reaper.defer(main)

reaper.atexit(function()
  reaper.SetExtState(EXT, "running",    "0", true)
  reaper.SetExtState(EXT, "sync_state", "0", false)
  local btn_id = tonumber(reaper.GetExtState(EXT, "btn_cmd_id"))
  if btn_id and btn_id ~= 0 then
    reaper.SetToggleCommandState(1, btn_id, 0)
    reaper.RefreshToolbar2(1, btn_id)
  end
  if gui_visible then gfx.quit() end
end)
