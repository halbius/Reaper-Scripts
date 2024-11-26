
function has_items_in_timesel(track, start_time, end_time)

  local item_count = reaper.CountTrackMediaItems(track)
  for i = 0, item_count -1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    
    if (item_start < end_time and item_end > start_time) then
      return true
    end
    
  end
  return false

end


function hide_empty_tracks_in_timesel()

  visible_track_count = 0
  local track_count = reaper.CountTracks(0)
  local start_time, end_time = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false)
  trackList = {}
  for i=0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    
    if has_items_in_timesel(track, start_time, end_time) then
    
      -- reaper.SetTrackSelected(track, true)
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
      
      trackList[visible_track_count] = track
      
      visible_track_count = visible_track_count + 1
      
    else
    
      -- reaper.SetTrackSelected(track, false)
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
    end
    
  end

end


function reset_track_height()

  local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000) )
  -- width = right - left
  height = bottom - top


    trackHeight = height / visible_track_count

  for i = 0, visible_track_count - 1 do
  
    local track = trackList[i]
    
    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", trackHeight)
    
  end

end


------------------------

hide_empty_tracks_in_timesel()

reset_track_height()

reaper.TrackList_AdjustWindows(true)

reaper.Main_OnCommand(reaper.NamedCommandLookup("40031"), 0) -- View: Zoom time selection

reaper.UpdateArrange()
