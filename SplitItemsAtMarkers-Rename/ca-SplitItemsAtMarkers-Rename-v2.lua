--------------------------
-- This Script Splits all items at markers
-- and then renames the new item with 'trackname'_'markername'
--
-- Author: Christian Alpen
--------------------------

CountMarkers = reaper.CountProjectMarkers(0)
CountTracks = reaper.CountTracks(0)
SelectedItemCount = 0
SelectedItemsList = {}

-- get the selected media items

CountMediaItems = reaper.CountMediaItems(0)
for  itemidx=0, CountMediaItems-1 do
  MediaItem = reaper.GetMediaItem( 0, itemidx )
  IsItemSelected = reaper.IsMediaItemSelected(MediaItem)


    if IsItemSelected == true then

        SelectedItemCount = SelectedItemCount + 1
        SelectedItemsList [SelectedItemCount] = MediaItem 

end

end

-- get Start+End over all selected items

for i=1, SelectedItemCount do

local selectedItem = SelectedItemsList[i]
local itemStart = reaper.GetMediaItemInfo_Value( selectedItem, "D_POSITION")
local itemLength = reaper.GetMediaItemInfo_Value( selectedItem, "D_LENGTH")
local itemEnd = itemStart + itemLength

if MarkerSelectionStart == nil or itemStart < MarkerSelectionStart then

    MarkerSelectionStart = itemStart

end

if MarkerSelectionEnd == nil or itemEnd > MarkerSelectionEnd then

    MarkerSelectionEnd = itemEnd

end


end



--reaper.ShowConsoleMsg("SelectionStart: " .. MarkerSelectionStart .. ", SelectionEnd: " .. MarkerSelectionEnd .."\n")
