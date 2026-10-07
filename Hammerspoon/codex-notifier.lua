-- Receive Stop events from codex/notifier-hammerspoon.py.
local activeApps = {
    ["com.github.wez.wezterm"] = true,
    ["com.openai.codex"] = true, -- ChatGPT.app's installed bundle ID
}

hs.urlevent.bind("codex-stopped", function(eventName, params)
    -- The frontmost app receives keyboard input, even if it has no focused window.
    local app = hs.application.frontmostApplication()
    if app and activeApps[app:bundleID()] then
        return
    end

    hs.notify.new({
        title = "Codex: Waiting for input",
        informativeText = params.message or "No output from Codex",
        soundName = "Glass",
    }):send()
end)
