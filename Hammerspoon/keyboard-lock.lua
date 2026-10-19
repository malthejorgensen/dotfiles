-- Ctrl+Option+Cmd+K locks keyboard input for 60 seconds; F1 unlocks early.
local keyboardLock = {}
local lockDuration = 60
local types = hs.eventtap.event.types
local cancelKey = hs.keycodes.map.f1
local pendingLock
local lockAlert
local countdownTimer
local unlockTimer

local function closeLockAlert()
    if lockAlert then
        hs.alert.closeSpecific(lockAlert, 0)
        lockAlert = nil
    end
end

function keyboardLock.unlock()
    keyboardLock.tap:stop()
    if countdownTimer then
        countdownTimer:stop()
        countdownTimer = nil
    end
    if unlockTimer then
        unlockTimer:stop()
        unlockTimer = nil
    end
    closeLockAlert()
    hs.alert.show("Keyboard unlocked")
end

local function showCountdown(remaining)
    closeLockAlert()
    -- Replace the persistent banner without a fade on each countdown tick.
    lockAlert = hs.alert.show(
        string.format("Keyboard locked — %ds remaining — press F1 to unlock", remaining),
        {fadeInDuration = 0}, "indefinite")
end

keyboardLock.tap = hs.eventtap.new({
    types.keyDown,
    types.keyUp,
    types.flagsChanged,
    types.systemDefined,
}, function(event)
    local eventType = event:getType()

    -- systemDefined also includes events unrelated to the keyboard.
    if eventType == types.systemDefined then
        return event:systemKey().key ~= nil
    end

    -- Swallow both halves of F1 so it doesn't reach the focused app.
    if eventType == types.keyUp and event:getKeyCode() == cancelKey then
        keyboardLock.unlock()
    end

    return true
end)

function keyboardLock.lock()
    if pendingLock or keyboardLock.tap:isEnabled() then
        return
    end

    -- Let apps receive the activation shortcut's modifier releases first.
    pendingLock = hs.timer.doEvery(0.05, function()
        local modifiers = hs.eventtap.checkKeyboardModifiers()
        if modifiers.cmd or modifiers.ctrl or modifiers.alt
            or modifiers.shift or modifiers.fn then
            return
        end

        pendingLock:stop()
        pendingLock = nil

        if hs.eventtap.isSecureInputEnabled() then
            hs.alert.show("Cannot lock keyboard while Secure Input is enabled")
            return
        end

        keyboardLock.tap:start()
        if keyboardLock.tap:isEnabled() then
            local deadline = hs.timer.secondsSinceEpoch() + lockDuration
            unlockTimer = hs.timer.doAfter(lockDuration, keyboardLock.unlock)
            showCountdown(lockDuration)
            countdownTimer = hs.timer.doEvery(1, function()
                -- Use elapsed time so delayed callbacks don't extend the lock.
                local remaining = math.ceil(deadline - hs.timer.secondsSinceEpoch())
                if remaining <= 0 then
                    keyboardLock.unlock()
                else
                    showCountdown(remaining)
                end
            end)
        else
            hs.alert.show("Could not lock keyboard; check Accessibility permissions")
        end
    end)
end

keyboardLock.hotkey = hs.hotkey.bind({"ctrl", "alt", "cmd"}, "K", nil, keyboardLock.lock)

return keyboardLock
