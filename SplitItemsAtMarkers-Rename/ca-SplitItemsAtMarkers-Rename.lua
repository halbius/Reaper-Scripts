--------------------------
-- This Script Splits all items at markers
-- and then renames the new item with 'trackname'_'markername'
--
-- Author: Christian Alpen
--------------------------

countMarkers = reaper.CountProjectMarkers(0)
countTracks = reaper.CountTracks(0)
    
for i=0, countMarkers-1 do -- cycle through markers


retval, isRgn, markerPosition, rgnend, markerName, idx = reaper.EnumProjectMarkers(i)

if isRgn == false -- wenn Marker und keine Region
then

  for iTr=0, countTracks-1 do -- cycle through tracks

      mediaTrack = reaper.GetTrack( 0, iTr) 
      itemTrackCount = reaper.CountTrackMediaItems( mediaTrack )

      if itemTrackCount ~= nil
      then

        retval, trackName = reaper.GetTrackName( mediaTrack )
         

        for iItem=0, itemTrackCount-1 do

          mediaItem = reaper.GetTrackMediaItem( mediaTrack, iItem )
          itemStart = reaper.GetMediaItemInfo_Value( mediaItem, "D_POSITION")
          itemLength = reaper.GetMediaItemInfo_Value( mediaItem, "D_LENGTH")
          itemEnd = itemStart + itemLength
          



          if (itemStart < markerPosition and itemEnd > markerPosition) then

            newItem = reaper.SplitMediaItem( mediaItem, markerPosition )
            reaper.ShowConsoleMsg(tostring(mediaItem) .. ", " .. tostring(newItem) .."\n")
      
            newItemName = markerName .. "_" .. trackName
            take = reaper.GetActiveTake( newItem )
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", newItemName, true)


          end




        end
      end

    end



  end

end


