-- Verschiebt auf allen selektierten Tracks das nächste Item rechts vom Playcursor
-- inklusive kompletter Gruppen, relative Position bleibt erhalten

reaper.Undo_BeginBlock()

local playpos = reaper.GetCursorPosition()
local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count == 0 then return end

-- Liste aller Items, die verschoben werden sollen
local items_to_move = {}
local earliest_pos = math.huge

-- 1. Auf jedem selektierten Track das nächste Item rechts vom Playcursor finden
for t = 0, sel_track_count - 1 do
    local track = reaper.GetSelectedTrack(0, t)
    local item_count = reaper.CountTrackMediaItems(track)

    local next_item = nil
    local next_item_pos = math.huge

    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

        if pos >= playpos and pos < next_item_pos then
            next_item = item
            next_item_pos = pos
        end
    end

    if next_item then
        table.insert(items_to_move, next_item)
        if next_item_pos < earliest_pos then
            earliest_pos = next_item_pos
        end
    end
end

-- Wenn keine Items gefunden wurden → Ende
if #items_to_move == 0 then return end

-- 2. Offset berechnen (alle Items sollen relativ gleich verschoben werden)
local offset = playpos - earliest_pos

-- 3. Gruppen sammeln
local group_ids = {}
for _, item in ipairs(items_to_move) do
    local gid = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if gid > 0 then
        group_ids[gid] = true
    end
end

-- 4. Alle Items, die verschoben werden müssen (inkl. Gruppen), einsammeln
local final_items = {}

-- Erst die direkten Items
for _, item in ipairs(items_to_move) do
    final_items[item] = true
end

-- Dann alle Items aus Gruppen
local total_items = reaper.CountMediaItems(0)
for i = 0, total_items - 1 do
    local item = reaper.GetMediaItem(0, i)
    local gid = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if gid > 0 and group_ids[gid] then
        final_items[item] = true
    end
end

-- 5. Alle gesammelten Items verschieben
for item, _ in pairs(final_items) do
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos + offset)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Move next items on selected tracks (with groups) to playcursor", -1)

--[[

-- Nächstes Item rechts vom Playcursor auf dem selektierten Track
-- inklusive kompletter Item-Gruppe verschieben

reaper.Undo_BeginBlock()

local playpos = reaper.GetCursorPosition()
local track = reaper.GetSelectedTrack(0, 0)
if not track then return end

local item_count = reaper.CountTrackMediaItems(track)
local next_item = nil
local next_item_pos = math.huge

-- Suche das nächste Item rechts vom Playcursor
for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

    if pos >= playpos and pos < next_item_pos then
        next_item = item
        next_item_pos = pos
    end
end

if not next_item then return end

-- Offset berechnen
local offset = playpos - next_item_pos

-- Gruppenzugehörigkeit ermitteln
local group_id = reaper.GetMediaItemInfo_Value(next_item, "I_GROUPID")

-- Wenn Item Teil einer Gruppe ist → alle Items der Gruppe verschieben
if group_id > 0 then
    local total_items = reaper.CountMediaItems(0)

    for i = 0, total_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        if reaper.GetMediaItemInfo_Value(item, "I_GROUPID") == group_id then
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos + offset)
        end
    end

else
    -- Item ist nicht gruppiert → nur dieses Item verschieben
    reaper.SetMediaItemInfo_Value(next_item, "D_POSITION", playpos)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Move next item (with group) to playcursor", -1)


]]--
