selectedItem = reaper.GetMediaItem( 0, 0)

reaper.SetMediaItemInfo_Value( selectedItem, 'D_POSITION', 3600 )
itemLength = reaper.GetMediaItemInfo_Value( selectedItem, 'D_LENGTH')

endMarkerPos = itemLength + 3600

reaper.SetProjectMarker( 1, 0, 3600, 0, "")
reaper.SetProjectMarker( 2, 0, endMarkerPos, 0, "")
