--[[
    Ripple Edit Hotkeys (L = All Tracks, K = Single Track)
    - Nutzt DEINE Action-IDs
    - Benötigt JS_ReaScriptAPI
--]]

-- Deine Action IDs
local RIPPLE_PER_TRACK = 40310  -- per-track (deine Zuordnung)
local RIPPLE_ALL       = 40311  -- all tracks
local RIPPLE_OFF       = 40309  -- off

-- Virtuelle Tasten
local KEY_L = 0x4B  -- L
local KEY_K = 0x4A  -- K

local last_L = false
local last_K = false

-- Aktuellen Ripple-Modus auslesen
-- 0 = off, 1 = per-track, 2 = all tracks
local function getRippleState()
    if reaper.GetToggleCommandState(RIPPLE_PER_TRACK) == 1 then
        return 1
    elseif reaper.GetToggleCommandState(RIPPLE_ALL) == 1 then
        return 2
    else
        return 0
    end
end

local function setRipple(mode)
    local current = getRippleState()
    if current == mode then return end

    if mode == 0 then
        reaper.Main_OnCommand(RIPPLE_OFF, 0)
    elseif mode == 1 then
        reaper.Main_OnCommand(RIPPLE_PER_TRACK, 0)
    elseif mode == 2 then
        reaper.Main_OnCommand(RIPPLE_ALL, 0)
    end
end

function loop()
    local keyState = reaper.JS_VKeys_GetState(0)
    if not keyState then
        reaper.defer(loop)
        return
    end

    local L_down = keyState:byte(KEY_L + 1) ~= 0
    local K_down = keyState:byte(KEY_K + 1) ~= 0


    -- L gedrückt → Ripple ALL
    if L_down and not last_L then
        setRipple(2)
    end
    -- L losgelassen → Ripple OFF
    if not L_down and last_L then
        setRipple(0)
    end

    -- K gedrückt → Ripple SINGLE
    if K_down and not last_K then
        setRipple(1)
    end
    -- K losgelassen → Ripple OFF
    if not K_down and last_K then
        setRipple(0)
    end

    last_L = L_down
    last_K = K_down

    reaper.defer(loop)
end

if not reaper.JS_VKeys_GetState then
    reaper.MB("JS_ReaScriptAPI ist nicht installiert!", "Fehler", 0)
else
    loop()
end
