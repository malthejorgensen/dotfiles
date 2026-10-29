local obj = {}
obj.__index = obj

obj.name = "GithubPRClipboardLink"
obj.version = "0.1"
obj.author = "Malthe Jørgensen <malthe.jorgensen@gmail.com>"
obj.license = "MIT"

function obj:init()
log = hs.logger.new('GithubPRClipboardLink','debug')

githubPRClipboardWatcher = hs.pasteboard.watcher.new(function(contents)
    if not contents then return end

    local url = contents:match("^%s*(.-)%s*$")
    local repo, number, suffix = url:match(
        "^https://github%.com/[%w-]+/([%w_.-]+)/pull/(%d+)(.*)$"
    )

    if repo and (suffix == "" or suffix == "/changes") then
        -- Solution A: Markdown
        -- hs.pasteboard.setContents(
        --     string.format("[%s#%s](%s)", repo, number, url)
        -- )

        -- Solution B: HTML + Markdown
        local label = string.format("%s#%s", repo, number)

        hs.pasteboard.writeAllData({
            ["public.html"] = string.format(
                '<a href="%s">%s</a>', url, label
            ),
            ["public.utf8-plain-text"] = string.format(
                "[%s](%s)", label, url
            ),
        })
    end
end)

end

return obj
