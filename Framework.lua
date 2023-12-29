-- Made by Fittergem with cStudio

-- REQUIREMENTS

local CONFIG = require(script.Parent:WaitForChild("Config"))
local ANIM = require(script.Parent:WaitForChild("Animations"))

local framework = {}

-- SERVICES

local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- LOCALS

local mouseAccelerationX = 0
local mouseAccelerationY = 0

local pages = {} -- Table also contains app information
local positions = {} -- All the possible positions apps can be on each page
local currentPage = 1
local appsOnPage = 0
local appsPerPage

local currentTheme = CONFIG.defaultGestureTheme

local phoneFrame = script.Parent:WaitForChild("PhoneFrame")
local powerButton = phoneFrame:WaitForChild("Power")
local volumeUpButton = phoneFrame:WaitForChild("VolumeUp")
local volumeDownButton = phoneFrame:WaitForChild("VolumeDown")
local phone = phoneFrame:WaitForChild("Phone")
local screen = phone:WaitForChild("Screen")
local bootscreen = screen:WaitForChild("Bootup")
local lockscreen = screen:WaitForChild("Lockscreen")
local homescreen = screen:WaitForChild("Homescreen")
local appsPage = homescreen:WaitForChild("1")

-- FRAMEWORK VARIABLES

framework.powerStatus = CONFIG.powerStatus
framework.data = {}

-- FUNCTIONS

-- Manage the device power system (duh)
local function manageDevicePower()
	if framework.powerStatus == 1 then -- Phone is on homescreen to start
		bootscreen.Visible = false
		lockscreen.Visible = false
		homescreen.Visible = true
		screen.GroupTransparency = 0
		screen.Visible = true
	elseif framework.powerStatus == 2 then -- Phone is on lockscreen to start
		bootscreen.Visible = false
		lockscreen.Visible = true
		homescreen.Visible = false
		screen.GroupTransparency = 0
		screen.Visible = true
	elseif framework.powerStatus == 3 then -- Bootup phone to start
		bootscreen.Visible = true
		lockscreen.Visible = false
		homescreen.Visible = false
		screen.GroupTransparency = 0
		screen.Visible = true
	elseif framework.powerStatus == 4 then -- Phone is asleep to start
		bootscreen.Visible = false
		lockscreen.Visible = true
		homescreen.Visible = false
		screen.GroupTransparency = 1
		screen.Visible = false
	elseif framework.powerStatus == 5 then -- Phone is shutdown to start
		bootscreen.Visible = true
		lockscreen.Visible = false
		homescreen.Visible = false
		screen.GroupTransparency = 1
		screen.Visible = false
	end
	
	powerButton.MouseButton1Click:Connect(function()
		if framework.powerStatus == 1 then -- Phone is on
			ANIM.powerPhone(1, screen, homescreen, lockscreen, bootscreen)
			framework.powerStatus = 4
		elseif framework.powerStatus == 2 then -- Phone is on
			ANIM.powerPhone(2, screen, homescreen, lockscreen, bootscreen)
			framework.powerStatus = 4
		elseif framework.powerStatus == 3 then -- Phone is booting up
			-- NOTHING WILL HAPPEN LOL
		elseif framework.powerStatus == 4 then -- Phone is asleep
			ANIM.powerPhone(4, screen, homescreen, lockscreen, bootscreen)
			currentTheme = "Light"
			framework.powerStatus = 2
		elseif framework.powerStatus == 5 then -- Phone is shutdown
			ANIM.powerPhone(5, screen, homescreen, lockscreen, bootscreen)
			framework.powerStatus = 2
			currentTheme = "Light"
		end
	end)
end

-- Manage lockscreen
local function manageLockscreen()
	
end

-- Get mouse acceleration
local function getMouseAcceleration(): number
	local lastPos = uis:GetMouseLocation()
	local lastTime = os.time()
	
	runService.Heartbeat:Connect(function()
		local mousePos = uis:GetMouseLocation()
		
		if math.abs(lastTime - os.time()) >= 0.1 then
			mouseAccelerationX = math.floor(math.abs(mousePos.X - lastPos.X) + 0.5)
			mouseAccelerationY = math.floor(math.abs(mousePos.Y - lastPos.Y) + 0.5)
			lastPos = mousePos
		end
	end)
end

-- Creates pages inside of the pages table
local function createPage(makeNewPage: boolean, page: Frame)
	if makeNewPage then
		local newPage = Instance.new("Frame", appsPage.Parent)
		newPage.AnchorPoint = appsPage.AnchorPoint
		newPage.Size = appsPage.Size
		newPage.BackgroundTransparency = appsPage.BackgroundTransparency
		newPage.ZIndex = appsPage.ZIndex
		if #pages > 0 then
			newPage.Position = pages[#pages].page.Position + UDim2.new(1,0,0,0)
		else
			newPage.Position = UDim2.fromScale(.5,.5)
		end
		table.insert(pages, {page = newPage, apps = {}})
	else
		table.insert(pages, {page = page, apps = {}})
	end
	
	currentPage = #pages
	appsOnPage = 0
end

-- Get all the possible positions a page can have
local function getPossiblePositions()
	local onRow = 0
	local row = 1

	if CONFIG.automaticIcons then
		local rowsPerPage = math.floor((1/CONFIG.iconSize) - 1) -- Y axis
		local iconsPerRow = math.floor((1/CONFIG.iconSize) - 1) -- X axis
		
		-- Loop through each row and each icon spot available per row. Create a position using math and then move on to the next spot.
		for i = 1, rowsPerPage do
			for v = 1, iconsPerRow do
				onRow += 1

				local position = UDim2.fromScale((1/(iconsPerRow + 1)) * onRow, (1/(rowsPerPage)) * row)
				table.insert(positions, position)

				if onRow == iconsPerRow then
					row += 1
					onRow = 0
				end
			end
		end
	else
		-- Same thing as the above loop, only it uses the configuration defined rows and columns if automatic icons is disabled.
		for i = 1, CONFIG.rowsPerPage do
			for v = 1, CONFIG.iconsPerRow do
				onRow += 1
				
				local position = UDim2.fromScale((1/(CONFIG.iconsPerRow + 1)) * onRow, (1/(CONFIG.rowsPerPage + 1)) * row)
				table.insert(positions, position)
				
				if onRow == CONFIG.iconsPerRow then
					row += 1
					onRow = 0
				end
			end
		end
	end
	
	appsPerPage = #positions
end

local function getAppIndex(appName: string)
	for i, page in pairs(pages) do
		for v, app in pairs(page.apps) do
			if app.name == appName then
				return i, v
			end
		end
	end
end

-- Create apps as they are loaded
function framework.loadApp(appName: string, appButton: GuiButton, appFrame: CanvasGroup)
	-- Manage app icon sizing
	if not appButton:FindFirstChildOfClass("UIAspectRatioConstraint") then
		local AspectRatio = Instance.new("UIAspectRatioConstraint", appButton)
		AspectRatio.AspectRatio = 1
	end
	appButton.Size = UDim2.fromScale(CONFIG.iconSize, CONFIG.iconSize)
	
	-- Wait for the positions to load
	repeat task.wait() until appsPerPage ~= nil
	
	-- Create new page if max apps has been reached for current page
	if appsOnPage == appsPerPage then
		createPage(true)
	end
	
	appsOnPage += 1
	
	-- Position the apps after the positions have been loaded
	appButton.Position = positions[appsOnPage]
	
	-- Get app light theme
	local lightTheme
	local appBackground = Color3.new(appFrame.BackgroundColor3.R, appFrame.BackgroundColor3.G, appFrame.BackgroundColor3.B)
	local backgroundValue = (appBackground.R + appBackground.G + appBackground.B)/3
	if backgroundValue <= .5 then
		lightTheme = "Dark"
	else
		lightTheme = "Light"
	end
	
	-- Create new app table inside of the page table
	pages[#pages].apps[appsOnPage] = {
		name = appName,
		button = appButton,
		frame = appFrame,
		position = positions[appsOnPage],
		onPage = currentPage,
		theme = lightTheme,
		onShelf = false,
		open = false,
		moving = false
	}
	
	appButton.Parent = pages[#pages].page	
	appButton.Visible = true
	
	local pageIndex, appIndex = getAppIndex(appName)
	
	appButton.MouseButton1Down:Connect(function()
		currentTheme =  pages[pageIndex].apps[appIndex].theme
		ANIM.openApp(appButton, appFrame, homescreen)
		pages[pageIndex].apps[appIndex].open = true
	end)
end

-- Manage the gesture bar
function framework.manageGesture(gestureBar: GuiButton)
	if not CONFIG.gestureNavbar then return end
	local startPos = uis:GetMouseLocation().Y
	local pressed = false
	
	-- Get a start position and set the current state to pressed
	gestureBar.MouseButton1Down:Connect(function()
		pressed = true		
		startPos = uis:GetMouseLocation().Y
	end)
	
	-- Determine if the user has swiped the gesture based on the configuration settings and then close all apps that are open
	runService.Heartbeat:Connect(function()
		if (startPos - uis:GetMouseLocation().Y) >= CONFIG.gestureThreshold and mouseAccelerationY >= CONFIG.gestureAcceleration and pressed then
			pressed = false
			for i, page in pairs(pages) do
				for v, app in pairs(page.apps) do
					if app.open then
						currentTheme = CONFIG.defaultGestureTheme
						ANIM.closeApp(app.button, app.frame, homescreen, app.position)
						app.open = false
					end
				end
			end
		end
	end)
	
	-- When the input ends set pressed to false if the button was pressed
	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and pressed then
			pressed = false
		end
	end)
	
	local recentTheme = CONFIG.defaultGestureTheme
	
	-- Constantly check for color themes to change
	if CONFIG.dynamicGesture then
		runService.Heartbeat:Connect(function()
			if currentTheme ~= recentTheme then
				recentTheme = currentTheme
				ANIM.changeGestureColor(gestureBar, currentTheme)
			end
		end)
	end
end

-- INITIALIZATION

createPage(false, appsPage)
getPossiblePositions()
getMouseAcceleration()

if CONFIG.powerStatus ~= 0 then
	manageDevicePower()
end

return framework
