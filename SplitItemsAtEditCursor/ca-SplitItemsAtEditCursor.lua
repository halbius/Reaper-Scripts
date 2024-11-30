
local cursor_position = reaper.GetCursorPosition()

local item_count = reaper.CountMediaItems(0)

reaper.SelectAllMediaItems( 0, false )

for i = item_count - 1, 0, -1 do

    local item = reaper.GetMediaItem(0, i)

    local item_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')

    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')



    if (item_start < cursor_position and cursor_position < item_end) then


        local new_item = reaper.SplitMediaItem(item, cursor_position)
        reaper.SetMediaItemSelected(new_item, true)
    
      
    end

end

reaper.UpdateArrange()
