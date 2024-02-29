local dock = hs.axuielement.applicationElement('Dock');
if not dock then print('No Dock found! Stopping script...'); return; end;

local dockList = dock[1];
local lastDockWidth;

local dockIcons = {};

local function isPointInRect(point, rect)
    return point.x >= rect.x and point.x <= rect.x + rect.w and
           point.y >= rect.y and point.y <= rect.y + rect.h;
end;

local function updateDockIcons()
    dockIcons = {};

    for i, v in ipairs(dockList) do -- ipairs for children, pairs for attributes.
        local title = v.AXTitle;
        local axURL = v.AXURL;
        if title and axURL then
            local position, size = v.AXPosition, v.AXSize;
            dockIcons[title] = {
                path = axURL.filePath,
                rect = {x = position.x, y = position.y, w = size.w, h = size.h},
            };
        end;
    end;
end;

local function updateDockIconsIfNecessary()
    local dockWidth = dockList.AXSize.w;
    if dockWidth ~= lastDockWidth then
        lastDockWidth = dockWidth;
        updateDockIcons();
    end;
end;

local function handleMouseEvent(event)
    local mousePos = hs.mouse.absolutePosition();
    for title, dockIcon in pairs(dockIcons) do
        if isPointInRect(mousePos, dockIcon.rect) then
            -- local app = hs.application.get(title);
            local app;
            if not app then
                for _, runningApp in ipairs(hs.application.runningApplications()) do
                    -- Allows for apps like Visual Studio Code to be found.
                    if runningApp:path() == dockIcon.path then
                        app = runningApp;
                        break;
                    end;
                end;
            end;

            if app and app:isFrontmost() then
                app:hide();
                return true; -- Block mouse event from passing and re-showing window.
            end;
        end;
    end;
end;

hs.console.clearConsole();

updateDockIconsIfNecessary();
timer = hs.timer.doEvery(1, updateDockIconsIfNecessary); -- Putting the timer in a variable in case of garbage collection.

-- Can't make the mouseWatcher variable local because of some garbage collection issue. https://github.com/Hammerspoon/hammerspoon/issues/681
mouseWatcher = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown}, handleMouseEvent);
mouseWatcher:start()
