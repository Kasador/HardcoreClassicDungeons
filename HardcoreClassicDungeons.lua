-- WoW API Declarations
local UnitLevel, UnitClass, SlashCmdList = UnitLevel, UnitClass, SlashCmdList

-- Initialize Variables
local showAllDungeons = false
local dungeonTextFrames = {}

-- Create Main Frame with a classic interface style
local frame = CreateFrame("Frame", "HCDFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(700, 500)
frame:SetPoint("CENTER", UIParent, "CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetFrameStrata("HIGH")  -- Set higher Z-index so it stays on top
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()  -- Initially hide the frame

-- Title
local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", frame, "TOP", 0, -4)  -- Adjust the padding
titleText:SetText("Hardcore Classic Dungeons")

-- Display character level and name
local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
levelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
local playerName = UnitName("player")  -- Get the player's name
levelText:SetText("Level " .. UnitLevel("player") .. "\n" .. playerName)  -- Display level and name on separate lines

-- Role Selection Icons (Tank, Healer, DPS) with custom icons
local roleIcons = {
    ["Tank"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\TankIcon.tga",
    ["Healer"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\HealerIcon.tga",
    ["DPS"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\DPSIcon.tga",    -- Custom DPS icon
}

local function CreateRoleIcons()
    local _, class = UnitClass("player")

    local availableRoles = {
        TANK = {"PALADIN", "WARRIOR", "DRUID"},
        HEALER = {"PRIEST", "PALADIN", "DRUID", "SHAMAN"},
        DPS = {"WARRIOR", "PALADIN", "DRUID", "PRIEST", "SHAMAN", "MAGE", "ROGUE", "WARLOCK", "HUNTER"}
    }

    local roles = {"Tank", "Healer", "DPS"}
    for i, role in ipairs(roles) do
        -- Create the icon button (without check)
        local roleIcon = CreateFrame("Frame", "HCD" .. role .. "Icon", frame)
        roleIcon:SetSize(64, 64)
        roleIcon:SetPoint("TOP", frame, "TOP", (-64 + (i - 2) * 90), -40)

        -- Set role icon using the custom icon paths
        local icon = roleIcon:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexture(roleIcons[role])

        -- Create a separate check button below the icon
        local roleCheckButton = CreateFrame("CheckButton", "HCD" .. role .. "CheckButton", frame, "UICheckButtonTemplate")
        roleCheckButton:SetSize(24, 24)
        roleCheckButton:SetPoint("TOP", roleIcon, "BOTTOM", 0, -10)

        -- Gray out the icon and disable the check button if the class doesn't have that role
        if not tContains(availableRoles[role:upper()], class) then
            icon:SetVertexColor(0.5, 0.5, 0.5)  -- Gray out the icon
            roleCheckButton:Disable()           -- Disable the check button
            roleCheckButton:SetAlpha(0.5)       -- Make the check button semi-transparent
        else
            icon:SetVertexColor(1, 1, 1)        -- Normal color if available
            roleCheckButton:SetAlpha(1)         -- Normal opacity for check button
        end
    end
end


-- Call the function to create role icons
CreateRoleIcons()

-- Create a scroll frame for the dungeon list
local scrollFrame = CreateFrame("ScrollFrame", "HCDScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(400, 300)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -120)

-- Scroll child frame (content inside the scroll)
local content = CreateFrame("Frame", "HCDScrollChild", scrollFrame)
content:SetSize(380, 600)  -- Arbitrary size, will adjust based on content
scrollFrame:SetScrollChild(content)

-- Function to clear the content frame by hiding and unparenting FontStrings
local function ClearDungeonList()
    for _, fontString in ipairs(dungeonTextFrames) do
        fontString:Hide()
        fontString:SetParent(nil)
    end
    dungeonTextFrames = {}  -- Reinitialize as an empty table
end

-- Function to display dungeon information
local function CreateDungeonList(showAll)
    ClearDungeonList()  -- Clear existing dungeon list

    local dungeons = {
        {"Ragefire Chasm", 14, 18},
        {"Deadmines", 20, 24},
        {"Wailing Caverns", 20, 24},
        {"Shadowfang Keep", 24, 28},
        {"Blackfathom Deeps", 26, 30},
        {"The Stockade", 27, 31},
        {"Razorfen Kraul", 31, 35},
        {"Gnomeregan", 32, 36},
        {"Scarlet Monastery Graveyard", 32, 36},
        {"Scarlet Monastery Library", 35, 39},
        {"Scarlet Monastery Armory", 38, 42},
        {"Razorfen Downs", 39, 43},
        {"Scarlet Monastery Cathedral", 40, 44},
        {"Uldaman", 45, 49},
        {"Zul'Farrak", 46, 50},
        {"Maraudon", 49, 53},
        {"Sunken Temple", 53, 57},
        {"Dire Maul East", 56, 60},
        {"Blackrock Depths", 57, 60},
        {"Stratholme Live", 58, 60},
        {"Blackrock Spire Lower", 58, 60},
        {"Dire Maul West", 59, 60},
        {"Dire Maul North", 60, 60},
        {"Stratholme Undead", 60, 60},
        {"Blackrock Spire Upper", 60, 60},
        {"Scholomance", 60, 60},
    }

    local playerLevel = UnitLevel("player")
    local yOffset = -25
    local contentHeight = 0

    -- Display warning if player level is too low
    if playerLevel <= 17 and not showAll then
        local warningText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warningText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        warningText:SetTextColor(1, 0, 0)  -- Red text
        warningText:SetText("You're currently too low of a level for dungeons.")
        yOffset = yOffset - 20
        contentHeight = contentHeight + 20
        table.insert(dungeonTextFrames, warningText)
    else
        for _, dungeon in ipairs(dungeons) do
            local dungeonName, minLevel, maxLevel = unpack(dungeon)
            if showAll or (playerLevel >= minLevel - 2 and playerLevel <= maxLevel + 1) then
                local dungeonText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                dungeonText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

                -- Color coding
                if playerLevel < minLevel then
                    dungeonText:SetTextColor(1, 0, 0) -- Red
                elseif playerLevel >= minLevel and playerLevel <= maxLevel then
                    dungeonText:SetTextColor(1, 1, 0) -- Yellow
                else
                    dungeonText:SetTextColor(0, 1, 0) -- Green
                end

                dungeonText:SetText(dungeonName .. ": " .. minLevel .. " - " .. maxLevel)
                yOffset = yOffset - 20
                contentHeight = contentHeight + 20
                table.insert(dungeonTextFrames, dungeonText)
            end
        end
    end

    content:SetHeight(contentHeight)
    scrollFrame:UpdateScrollChildRect()
end

-- Toggle button to show all dungeons or just relevant ones
local toggleButton = CreateFrame("Button", "HCDToggleButton", frame, "UIPanelButtonTemplate")
toggleButton:SetSize(100, 30)
toggleButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 30)
toggleButton:SetText("Show All")
toggleButton:SetScript("OnClick", function()
    showAllDungeons = not showAllDungeons
    if showAllDungeons then
        toggleButton:SetText("Show Less")
    else
        toggleButton:SetText("Show All")
    end
    CreateDungeonList(showAllDungeons)
end)

-- Slash command to toggle the frame visibility
local function ToggleHCDFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Register slash command
SLASH_HCD1 = "/hcd"
SlashCmdList["HCD"] = ToggleHCDFrame

-- Initial creation of dungeon list
CreateDungeonList(false)

print("Slash command '/hcd' registered.")
