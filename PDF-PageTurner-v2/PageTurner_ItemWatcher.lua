-- PageTurner ItemWatcher v3
-- Wird vom Web-Interface per ACTION-Kommando gestartet.
-- Stoppt sich selbst wenn der ExtState-Flag "itemWatcherRun" auf "0" gesetzt wird.
--
-- Start:  SET/EXTSTATE/pagesWebRC/itemWatcherRun/1  +  ACTION/_RS...
-- Stop:   SET/EXTSTATE/pagesWebRC/itemWatcherRun/0
--
-- Schreibt aktiven Item-Namen nach: GET/EXTSTATE/pagesWebRC/activeItem

local EXT_SECTION  = "pagesWebRC"
local EXT_KEY      = "activeItem"
local FLAG_KEY     = "itemWatcherRun"
local INTERVAL     = 0.1
local lastTime     = 0
local lastName     = ""

-- Laufzeit-Flag beim Start setzen
reaper.SetExtState(EXT_SECTION, FLAG_KEY, "1", false)

function shouldRun()
  local flag = reaper.GetExtState(EXT_SECTION, FLAG_KEY)
  return flag ~= "0"
end

function findActiveItem()
  local playState = reaper.GetPlayState()
  if playState ~= 1 and playState ~= 5 then return "" end

  local playPos    = reaper.GetPlayPosition()
  local trackCount = reaper.CountTracks(0)

  for t = 0, trackCount - 1 do
    local track     = reaper.GetTrack(0, t)
    local itemCount = reaper.CountTrackMediaItems(track)

    for i = 0, itemCount - 1 do
      local item  = reaper.GetTrackMediaItem(track, i)
      local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local len   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

      if playPos >= start and playPos < (start + len) then
        local take = reaper.GetActiveTake(item)
        if take ~= nil then
          local ok, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
          if ok and name ~= nil and name ~= "" then
            return name
          end
        end
      end
    end
  end

  return ""
end

function tick()
  -- Selbst beenden wenn Flag gelöscht wurde
  if not shouldRun() then
    reaper.SetExtState(EXT_SECTION, EXT_KEY, "", false) -- activeItem leeren
    return  -- kein weiteres defer → Script stoppt
  end

  local now = reaper.time_precise()
  if now - lastTime >= INTERVAL then
    lastTime = now
    local name = findActiveItem()
    if name ~= lastName then
      lastName = name
      reaper.SetExtState(EXT_SECTION, EXT_KEY, name, false)
    end
  end

  reaper.defer(tick)
end

reaper.defer(tick)
