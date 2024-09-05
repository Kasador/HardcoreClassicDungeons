-- WoW API Declarations
local UnitLevel, UnitClass, SlashCmdList = UnitLevel, UnitClass, SlashCmdList

-- Initialize Variables
local showAllDungeons = false
local dungeonTextFrames = {}
local selectedRoles = {TANK = false, HEALER = false, DPS = false}

-- Role Selection Icons (Tank, Healer, DPS) with custom icons
local roleIcons = {
    ["Tank"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\TankIcon.tga",
    ["Healer"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\HealerIcon.tga",
    ["DPS"] = "Interface\\AddOns\\HardcoreClassicDungeons\\Icons\\DPSIcon.tga",
}

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
titleText:SetPoint("TOP", frame, "TOP", 0, -4)
titleText:SetText("Hardcore Classic Dungeons")

-- Display character level and name
local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
levelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
local playerName = UnitName("player")
levelText:SetText("Level " .. UnitLevel("player") .. "\n" .. playerName)

-- Scroll frame and content setup
local scrollFrame = CreateFrame("ScrollFrame", "HCDScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(250, 300)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -110)

-- Add a solid non-transparent border using NineSlice API
local borderFrame = CreateFrame("Frame", "DungeonListBorder", frame, "TooltipBorderedFrameTemplate")
borderFrame:SetSize(250, 300)
borderFrame:SetPoint("TOPLEFT", scrollFrame, -15, 10)
borderFrame:SetPoint("BOTTOMRIGHT", scrollFrame, 30, -10)

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

-- Helper function to display the dungeon list for any role
local function DisplayDungeonList(dungeonList, showAll)
    local playerLevel = UnitLevel("player")
    local yOffset = -15
    local contentHeight = 0

    if playerLevel <= 17 and not showAll then
        local warningText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warningText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        warningText:SetTextColor(1, 0, 0)
        warningText:SetText("No Dungeons Available.")
        yOffset = yOffset - 20
        contentHeight = contentHeight + 20
        table.insert(dungeonTextFrames, warningText)
    else
        for _, dungeon in ipairs(dungeonList) do
            local dungeonName, minLevel, maxLevel = unpack(dungeon)

            if showAll or (playerLevel >= minLevel - 2 and playerLevel <= maxLevel + 1) then
                local dungeonText = CreateFrame("Button", nil, content)
                dungeonText:SetSize(250, 20)
                dungeonText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

                local dungeonLabel = dungeonText:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                dungeonLabel:SetPoint("LEFT", dungeonText, "LEFT", 10, 0)
                dungeonLabel:SetText(dungeonName .. ": " .. minLevel .. " - " .. maxLevel)

                if playerLevel < minLevel then
                    dungeonLabel:SetTextColor(1, 0, 0)
                elseif playerLevel >= minLevel and playerLevel <= maxLevel then
                    dungeonLabel:SetTextColor(1, 1, 0)
                else
                    dungeonLabel:SetTextColor(0, 1, 0)
                end

                dungeonText:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

                dungeonText:SetScript("OnEnter", function(self)
                    dungeonLabel:SetTextColor(0, 1, 1)
                end)

                dungeonText:SetScript("OnLeave", function(self)
                    if playerLevel < minLevel then
                        dungeonLabel:SetTextColor(1, 0, 0)
                    elseif playerLevel >= minLevel and playerLevel <= maxLevel then
                        dungeonLabel:SetTextColor(1, 1, 0)
                    else
                        dungeonLabel:SetTextColor(0, 1, 0)
                    end
                end)

                dungeonText:SetScript("OnClick", function(self)
                    print(dungeonName)
                end)

                yOffset = yOffset - 20
                contentHeight = contentHeight + 20
                table.insert(dungeonTextFrames, dungeonText)
            end
        end
    end

    content:SetHeight(contentHeight)
    scrollFrame:UpdateScrollChildRect()
end

-- Function to create the default dungeon list on load
local function CreateDungeonListMain(showAll)
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

    DisplayDungeonList(dungeons, showAll)
end

-- Dungeon lists for each role
local dungeonsTank = {
    {"Ragefire Chasm", 15, 18},
    {"Deadmines", 21, 24},
    {"Wailing Caverns", 21, 24},
    {"Shadowfang Keep", 25, 28},
    {"Blackfathom Deeps", 27, 30},
    {"The Stockade", 28, 31},
    {"Razorfen Kraul", 32, 35},
    {"Gnomeregan", 33, 36},
    {"Scarlet Monastery Graveyard", 33, 36},
    {"Scarlet Monastery Library", 36, 39},
    {"Scarlet Monastery Armory", 39, 42},
    {"Razorfen Downs", 40, 43},
    {"Scarlet Monastery Cathedral", 41, 44},
    {"Uldaman", 46, 49},
    {"Zul'Farrak", 47, 50},
    {"Maraudon", 50, 53},
    {"Sunken Temple", 54, 57},
    {"Dire Maul East", 57, 60},
    {"Blackrock Depths", 58, 60},
    {"Stratholme Live", 59, 60},
    {"Blackrock Spire Lower", 59, 60},
    {"Dire Maul West", 60, 60},
    {"Dire Maul North", 60, 60},
    {"Stratholme Undead", 60, 60},
    {"Blackrock Spire Upper", 60, 60},
    {"Scholomance", 60, 60},
}

local dungeonsHealer = {
    {"Ragefire Chasm", 13, 18},
    {"Deadmines", 19, 24},
    {"Wailing Caverns", 19, 24},
    {"Shadowfang Keep", 23, 28},
    {"Blackfathom Deeps", 25, 30},
    {"The Stockade", 26, 31},
    {"Razorfen Kraul", 30, 35},
    {"Gnomeregan", 31, 36},
    {"Scarlet Monastery Graveyard", 31, 36},
    {"Scarlet Monastery Library", 34, 39},
    {"Scarlet Monastery Armory", 37, 42},
    {"Razorfen Downs", 38, 43},
    {"Scarlet Monastery Cathedral", 39, 44},
    {"Uldaman", 44, 49},
    {"Zul'Farrak", 45, 50},
    {"Maraudon", 48, 53},
    {"Sunken Temple", 52, 57},
    {"Dire Maul East", 55, 60},
    {"Blackrock Depths", 56, 60},
    {"Stratholme Live", 57, 60},
    {"Blackrock Spire Lower", 57, 60},
    {"Dire Maul West", 58, 60},
    {"Dire Maul North", 59, 60},
    {"Stratholme Undead", 59, 60},
    {"Blackrock Spire Upper", 59, 60},
    {"Scholomance", 59, 60},
}

local dungeonsDPS = {
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

-- Function to determine which role's dungeon list to display
local function UpdateDungeonListBasedOnRoles()
    ClearDungeonList() -- Clear the previous list
    -- Always display the main dungeon list first
    CreateDungeonListMain(showAllDungeons)
    
    -- Then append role-specific lists if roles are selected
    if selectedRoles.DPS then
        ClearDungeonList();
        DisplayDungeonList(dungeonsDPS, showAllDungeons)
    end
    if selectedRoles.HEALER then
        ClearDungeonList();
        DisplayDungeonList(dungeonsHealer, showAllDungeons)
    end
    if selectedRoles.TANK then
        ClearDungeonList();
        DisplayDungeonList(dungeonsTank, showAllDungeons)
    end
end

-- Create role icons for Tank, Healer, DPS with checkboxes
local function CreateRoleIcons()
    local _, class = UnitClass("player")

    local availableRoles = {
        TANK = {"PALADIN", "WARRIOR", "DRUID"},
        HEALER = {"PRIEST", "PALADIN", "DRUID", "SHAMAN"},
        DPS = {"WARRIOR", "PALADIN", "DRUID", "PRIEST", "SHAMAN", "MAGE", "ROGUE", "WARLOCK", "HUNTER"}
    }

    local roles = {"Tank", "Healer", "DPS"}
    for i, role in ipairs(roles) do
        -- Create the icon button
        local roleIcon = CreateFrame("Frame", "HCD" .. role .. "Icon", frame)
        roleIcon:SetSize(64, 64)
        roleIcon:SetPoint("TOP", frame, "TOP", (150 + (i - 2) * 90), -40)

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
            icon:SetVertexColor(0.5, 0.5, 0.5)
            roleCheckButton:Disable()
            roleCheckButton:SetAlpha(0.5)
        else
            icon:SetVertexColor(1, 1, 1)
            roleCheckButton:SetAlpha(1)
            -- Update dungeon list when checkbox is toggled
            roleCheckButton:SetScript("OnClick", function(self)
                selectedRoles[role:upper()] = self:GetChecked() and true or false
                UpdateDungeonListBasedOnRoles()
            end)
        end
    end
end

-- Call the function to create role icons
CreateRoleIcons()

-- Toggle button to show all dungeons or just relevant ones
local toggleButton = CreateFrame("Button", "HCDToggleButton", frame, "UIPanelButtonTemplate")
toggleButton:SetSize(100, 30)
toggleButton:SetPoint("BOTTOM", frame, "BOTTOM", -195, 30)
toggleButton:SetText("Show All")
toggleButton:SetScript("OnClick", function()
    showAllDungeons = not showAllDungeons
    if showAllDungeons then
        toggleButton:SetText("Show Less")
    else
        toggleButton:SetText("Show All")
    end
    UpdateDungeonListBasedOnRoles()
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

-- Initial creation of dungeon list (use the generic dungeon list on first load)
CreateDungeonListMain(false)

print("Slash command '/hcd' registered.")
