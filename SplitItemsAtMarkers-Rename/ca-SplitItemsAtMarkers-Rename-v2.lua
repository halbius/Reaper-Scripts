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

for i=0, CountMarkers-1 do -- cycle through markers


retval, isRgn, markerPosition, rgnend, markerName, idx = reaper.EnumProjectMarkers(i)

if (isRgn == false and markerPosition >= MarkerSelectionStart and markerPosition <= MarkerSelectionEnd) -- wenn Marker und keine Region
then

  for iTr=0, CountTracks-1 do -- cycle through tracks

      mediaTrack = reaper.GetTrack( 0, iTr) 
      itemTrackCount = reaper.CountTrackMediaItems( mediaTrack )

      if itemTrackCount ~= nil
      then

        retval, trackName = reaper.GetTrackName( mediaTrack )
         

        for iItem=0, itemTrackCount-1 do

          MediaItem = reaper.GetTrackMediaItem( mediaTrack, iItem )
          itemStart = reaper.GetMediaItemInfo_Value( MediaItem, "D_POSITION")
          itemLength = reaper.GetMediaItemInfo_Value( MediaItem, "D_LENGTH")
          itemEnd = itemStart + itemLength
          



          if (itemStart < markerPosition and itemEnd > markerPosition) then

            newItem = reaper.SplitMediaItem( MediaItem, markerPosition )
      
            newItemName = markerName .. "_" .. trackName
            take = reaper.GetActiveTake( newItem )
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", newItemName, true)


          end




        end
      end

    end



  end

end