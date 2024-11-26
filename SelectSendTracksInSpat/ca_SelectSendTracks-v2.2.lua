--Script Name : Show selected tracks and sends in TCP
--Author : Christian Alpen
--Description : Select SendTracks and show only selected tracks in TCP
--v2.1.0




function main()


-- get the sends of the tracks

local recTracksArray = {}
sendTracksArray = {}

  if reaper.CountTracks(0) ~= nil then
    arrayCount = 0
    for i = 1, reaper.CountTracks(0) do
      selTrack = reaper.GetSelectedTrack(0, i-1)
      if selTrack ~= nil then
        sendTracksArray[i] = selTrack
        recTracksArray[i] = reaper.GetTrackSendInfo_Value(selTrack, 0, 0, 'P_DESTTRACK')
        arrayCount = arrayCount + 1
      end
   end

  end


-- select send tracks

for i = 1, arrayCount do

if recTracksArray[i] == 0 then

  reaper.ShowConsoleMsg("Keine Sendtracks!")

else

  reaper.SetTrackSelected(recTracksArray[i], true)

end
end




-- set unselected tracks invisible

for i = reaper.CountTracks(0)- 1, 0, -1 do
  local track = reaper.GetTrack(0, i)

  local isSelected = reaper.IsTrackSelected(track)

    if isSelected == false then

      reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)
    else
      reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 1)

    end

end



--- minimize SendTracks

for i = 1, arrayCount  do

local track = sendTracksArray[i]
reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 1);

end


reaper.Main_OnCommand(reaper.NamedCommandLookup("40297"), 0) -- unselect all tracks
---------------


--- maximize Zoom Receive Tracks

--- First calculate the number of tracks, incl. envelopes

 env = 0
countEnv = 0

for i = 1, arrayCount  do -- loop through receive tracks

  local track = recTracksArray[i]
   env = reaper.CountTrackEnvelopes(track) -- get number of active tracks
  countEnv = countEnv + env

end

trackCount = arrayCount + countEnv -- all incl. track count, recTracks+Envelopes
maxHeight = 700
newMaxHeight = maxHeight - arrayCount -- calculate max height without send Tracks
myHeight = newMaxHeight / trackCount  -- new max. track height


-- set receive tracks and envelopes to new height

for i = 1, arrayCount  do --loop through receive tracks

  local track = recTracksArray[i]
  
  reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", myHeight) -- set new height for receive tracks
  
  local env_count = reaper.CountTrackEnvelopes(track)
     for i = 0, env_count - 1 do -- loop through envelopes
    
     local envelope = reaper.GetTrackEnvelope(track, i)
     
     local _, envchunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
     
       -- Check if the envelope is visible
       local is_visible = (envchunk:find("VIS") ~= nil)
     
    
    if is_visible then
       -- Set the new envelope height
       local new_envchunk = envchunk:gsub("LANEHEIGHT %d+", "LANEHEIGHT " .. myHeight)
       reaper.SetEnvelopeStateChunk(envelope, new_envchunk, false)
     end
   
    
    end

    
     
  
  

end

--------------


reaper.Main_OnCommand(reaper.NamedCommandLookup("40297"), 0) -- unselect all tracks



reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TVPAGEHOME"), 0) -- scroll home

reaper.UpdateArrange()

end

-------------


  if reaper.CountTracks(0) ~= nil then
    local selTrack = 0
    local selTrackCount = 0
    for i = 1, reaper.CountTracks(0) do
        selTrack = reaper.GetSelectedTrack(0, i-1)
        if selTrack ~= nil then
          selTrackCount = selTrackCount + 1
          
       end
    end
    
    if selTrackCount == 0 then
      reaper.ClearConsole()
      reaper.ShowConsoleMsg("Keine Spuren ausgewählt!\n")
      
    else
      main()
    end

  end

  
