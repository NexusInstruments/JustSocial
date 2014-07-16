-----------------------------------------------------------------------------------------------
-- Client Lua Script for JustSocial
-- Copyright (c) Chronosis. GNU GENERAL PUBLIC LICENSE Version 3
-- Version 0.0.4
-----------------------------------------------------------------------------------------------
 
require "Window"
require "FriendshipLib"
 
-----------------------------------------------------------------------------------------------
-- JustSocial Module Definition
-----------------------------------------------------------------------------------------------
local JustSocial = {} 
local knMaxNumberOfCircles = 5
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function JustSocial:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.guildOpen = false
	o.friendsOpen = false
	o.neighborsOpen = false
	o.circlesOpen = false

    return o
end

function JustSocial:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- JustSocial OnLoad
-----------------------------------------------------------------------------------------------
function JustSocial:OnLoad()
	-- Load custom sprite sheet
	Apollo.LoadSprites("JustSocialSprites.xml")

    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("JustSocial.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("ToggleSocialWindow", "OnJustFriendsOn", self)
	Apollo.RegisterEventHandler("Generic_OnJustFriendsOn", "OnJustFriendsOn", self)
	Apollo.RegisterEventHandler("Generic_OnJustCirclesOn", "OnJustCirclesOn", self)
	Apollo.RegisterEventHandler("Generic_OnJustGuildOn", "OnJustGuildOn", self)
	Apollo.RegisterEventHandler("Generic_OnJustNeighborsOn", "OnJustNeighborsOn", self)
	
	
	Apollo.RegisterTimerHandler("JustSocialUpdateCountTimer", "UpdateInterfaceMenuAlerts", self)
	Apollo.CreateTimer("JustSocialUpdateCountTimer", 0.1, true)
	--Apollo.StartTimer("JustSocialUpdateCountTimer")
	
	--local tKeyBindings = {}
	--GameLib.SetKeyBindings(tKeyBindings)
end

-----------------------------------------------------------------------------------------------
-- Just Social Add Interface Buttons
-----------------------------------------------------------------------------------------------
function JustSocial:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Just Friends", {"ToggleSocialWindow", "Social", "Icon_Windows32_UI_CRB_InterfaceMenu_Social"})
	--Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Just Friends", {"Generic_OnJustFriendsOn", "Social", "Icon_Windows32_UI_CRB_InterfaceMenu_Social"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Just Guild", {"Generic_OnJustGuildOn", "Guild", "sprAchievements_Icon_Group"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Just Circles", {"Generic_OnJustCirclesOn", "", "sprHolo_Friends_Account"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Just Neighbors", {"Generic_OnJustNeighborsOn", "", "JustSocialSprites:icon_neighbors"})
	
	self:UpdateInterfaceMenuAlerts()
end

function JustSocial:CountNeighborsOnline()
	local nNeighborsOnline = 0
	local tNeighbors = HousingLib.GetNeighborList() or {}

	for key, tCurrNeighbor in pairs(tNeighbors) do
		if tCurrNeighbor.fLastOnline == 0 then -- online / check for strWorldZone
			nNeighborsOnline = nNeighborsOnline + 1
		end
	end

	return nNeighborsOnline 
end

function JustSocial:CountGuildiesOnline()
	local nGuildiesOnline = 0
	for key, guildData in pairs(GuildLib.GetGuilds()) do
		if guildData:GetType() == GuildLib.GuildType_Guild then
			nGuildiesOnline = guildData:GetOnlineMemberCount()
		end
	end
	return nGuildiesOnline
end

function JustSocial:UpdateInterfaceMenuAlerts()
	local nGuildies = self:CountGuildiesOnline() -- Number of xxx online
	local nNeighbors = self:CountNeighborsOnline() -- Number of xxx online
	
	local nUnseenFriendInviteCount = 0
	for idx, tInvite in pairs(FriendshipLib.GetInviteList()) do
		if tInvite.bIsNew then
			nUnseenFriendInviteCount = nUnseenFriendInviteCount + 1
		end
	end
	for idx, tInvite in pairs(FriendshipLib.GetAccountInviteList()) do
		if tInvite.bIsNew then
			nUnseenFriendInviteCount = nUnseenFriendInviteCount + 1
		end
	end

	local nOnlineFriendCount = 0
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
		if tFriend.fLastOnline == 0 then
			nOnlineFriendCount = nOnlineFriendCount + 1
		end
	end
	for idx, tFriend in pairs(FriendshipLib.GetAccountList()) do
		if tFriend.arCharacters then
			nOnlineFriendCount = nOnlineFriendCount + 1
		end
	end

	local tGuildParams = nUnseenFriendInviteCount > 0 and {true, nil, nUnseenFriendInviteCount} or {false, nil, nOnlineFriendCount}
			
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Just Friends", tGuildParams)
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Just Guild", {false, nil, nGuildies})	
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Just Neighbors", {false, nil, nNeighbors})
end

-----------------------------------------------------------------------------------------------
-- JustSocial OnDocLoaded
-----------------------------------------------------------------------------------------------
function JustSocial:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndGuild = Apollo.LoadForm(self.xmlDoc, "JustGuildForm", nil, self)
		if self.wndGuild == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Guild Window for some reason.")
			return
		end
	    self.wndFriends = Apollo.LoadForm(self.xmlDoc, "JustFriendsForm", nil, self)
		if self.wndFriends == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Friends Window for some reason.")
			return
		end
		self.wndNeighbors = Apollo.LoadForm(self.xmlDoc, "JustNeighborsForm", nil, self)
		if self.wndNeighbors == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Neighbors Window for some reason.")
			return
		end
		self.wndCircles = Apollo.LoadForm(self.xmlDoc, "JustCirclesForm", nil, self)
		if self.wndCircles == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Circles Window for some reason.")
			return
		end
				
	    self.wndGuild:Show(false, true)
		self.wndFriends:Show(false, true)
		self.wndNeighbors:Show(false, true)
		self.wndCircles:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		--Apollo.
		Apollo.RegisterSlashCommand("jc", "OnJustCirclesOn", self)
		Apollo.RegisterSlashCommand("jf", "OnJustFriendsOn", self)
		Apollo.RegisterSlashCommand("jg", "OnJustGuildOn", self)
		Apollo.RegisterSlashCommand("jn", "OnJustNeighborsOn", self)			

		-- Do additional Addon initialization here
		self.wndCirclesFrame = self.wndCircles:FindChild("CirclesWindow")
		self.wndFriendsFrame = self.wndFriends:FindChild("FriendsWindow")
		self.wndGuildFrame = self.wndGuild:FindChild("GuildWindow")
		self.wndNeighborsFrame = self.wndNeighbors:FindChild("NeighborsWindow")
		
		--Apollo.StartTimer("RecalculateInvitesTimer")
	end
end

-----------------------------------------------------------------------------------------------
-- JustSocial Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/jc"
function JustSocial:OnJustCirclesOn()
	if self.circlesOpen ~= true then
		self.wndCircles:Invoke() -- show the window
		self:DrawCirclesWindow()
		Event_FireGenericEvent("GenericEvent_InitializeCircles", self.wndCirclesFrame)
		self.circlesOpen = true
	else
		self.wndCircles:Close() -- hide the window
		self.circlesOpen = false
	end
end

-- on SlashCommand "/jf"
function JustSocial:OnJustFriendsOn()
	if self.friendsOpen ~= true then
		self.wndFriends:Invoke() -- show the window
		Event_FireGenericEvent("GenericEvent_InitializeFriends", self.wndFriendsFrame)
		self.friendsOpen = true
	else
		self.wndFriends:Close() -- hide the window
		self.friendsOpen = false
	end

end

-- on SlashCommand "/jg"
function JustSocial:OnJustGuildOn()
	if self.guildOpen ~= true then
		self.wndGuild:Invoke() -- show the window
		Event_FireGenericEvent("GenericEvent_InitializeGuild", self.wndGuildFrame)
		self.guildOpen = true
	else
		self.wndGuild:Close() -- hide the window
		self.guildOpen = false
	end
end

-- on SlashCommand "/jn"
function JustSocial:OnJustNeighborsOn()
	if self.neighborsOpen ~= true then
		self.wndNeighbors:Invoke() -- show the window
		Event_FireGenericEvent("GenericEvent_InitializeNeighbors", self.wndNeighborsFrame)
		self.neighborsOpen = true
	else
		self.wndNeighbors:Close() -- hide the window
		self.neighborsOpen = false	
	end
end

-----------------------------------------------------------------------------------------------
-- JustSocialForm Functions
-----------------------------------------------------------------------------------------------
-- when the Cancel button is clicked
function JustSocial:OnCirclesCancel()
	self.wndCircles:Close() -- hide the window
	self.circlesOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyCircles")
end

-- when the Cancel button is clicked
function JustSocial:OnFriendsCancel()
	self.wndFriends:Close() -- hide the window
	self.friendsOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyFriends")
end

-- when the Cancel button is clicked
function JustSocial:OnGuildCancel()
	self.wndGuild:Close() -- hide the window
	self.guildOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyGuild")
end

-- when the Cancel button is clicked
function JustSocial:OnNeighborsCancel()
	self.wndNeighbors:Close() -- hide the window
	self.neighborsOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyNeighbors")
end

---------------------------------------------------------------------------------------------------
-- JustGuildForm Functions
---------------------------------------------------------------------------------------------------

function JustSocial:onGuildWindowClosed( wndHandler, wndControl )
	self.guildOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyGuild")
end

---------------------------------------------------------------------------------------------------
-- JustFriendsForm Functions
---------------------------------------------------------------------------------------------------

function JustSocial:onFriendsWindowClosed( wndHandler, wndControl )
	self.friendsOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyFriends")
end

function JustSocial:OnGuildButton( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("Generic_OnJustGuildOn")
end

function JustSocial:OnCircleButton( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("Generic_OnJustCirclesOn")
end

function JustSocial:OnNeighborButton( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("Generic_OnJustNeighborsOn")
end

---------------------------------------------------------------------------------------------------
-- JustNeighborsForm Functions
---------------------------------------------------------------------------------------------------

function JustSocial:onNeighborsWindowClosed( wndHandler, wndControl )
	self.neighborsOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyNeighbors")
end

---------------------------------------------------------------------------------------------------
-- JustCirclesForm Functions
---------------------------------------------------------------------------------------------------
function JustSocial:onCirclesWindowClosed( wndHandler, wndControl )
	self.circlesOpen = false
	--Event_FireGenericEvent("GenericEvent_DestroyCircles")
end

function JustSocial:DrawCirclesWindow()
	self.wndCircles:FindChild("SplashCircleItemContainer"):DestroyChildren() -- TODO: See if we can remove this

	-- Circles
	local nNumberOfCircles = 0
	local arGuilds = GuildLib.GetGuilds()
	table.sort(arGuilds, function(a,b) return (self:HelperSortCirclesChannelOrder(a,b)) end)
	for key, guildCurr in pairs(arGuilds) do
		if guildCurr:GetType() == GuildLib.GuildType_Circle then
			nNumberOfCircles = nNumberOfCircles + 1

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "SplashCirclesPickerItem", self.wndCircles:FindChild("SplashCircleItemContainer"), self)
			wndCurr:FindChild("SplashCirclesPickerBtn"):SetData(guildCurr)
			wndCurr:FindChild("SplashCirclesPickerBtnText"):SetText(guildCurr:GetName())
		end
	end

	-- Circle Add Btn
	if nNumberOfCircles < knMaxNumberOfCircles then
		Apollo.LoadForm(self.xmlDoc, "SplashCirclesAddItem", self.wndCircles:FindChild("SplashCircleItemContainer"), self)
		nNumberOfCircles = nNumberOfCircles + 1
	end

	-- Circle Blank Btn
	for idx = nNumberOfCircles + 1, knMaxNumberOfCircles do -- Fill in the rest with blanks
		Apollo.LoadForm(self.xmlDoc, "SplashCirclesUnusedItem", self.wndCircles:FindChild("SplashCircleItemContainer"), self)
	end
	self.wndCircles:FindChild("SplashCircleItemContainer"):ArrangeChildrenHorz(0)
end

function JustSocial:HelperSortCirclesChannelOrder(guildLhs, guildRhs)
	local chanLhs = guildLhs and guildLhs:GetChannel()
	local chanRhs = guildRhs and guildRhs:GetChannel()
	local strCommandLhs = chanLhs and chanLhs:GetCommand() or ""
	local strCommandRhs = chanRhs and chanRhs:GetCommand() or ""
	return strCommandLhs < strCommandRhs
end

---------------------------------------------------------------------------------------------------
-- SplashCirclesPickerItem Functions
---------------------------------------------------------------------------------------------------
function JustSocial:OnCircleItemCheck( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("GenericEvent_InitializeCircles", self.wndCirclesFrame, wndHandler:GetData())
end

function JustSocial:OnCircleItemUncheck( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("GenericEvent_DestroyCircles")
end

---------------------------------------------------------------------------------------------------
-- SplashCirclesAddItem Functions
---------------------------------------------------------------------------------------------------
function JustSocial:OnSplashCirclesAddBtn( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("EventGeneric_OpenCircleRegistrationPanel", self.wndCircles)
end

-----------------------------------------------------------------------------------------------
-- JustSocial Instance
-----------------------------------------------------------------------------------------------
local JustSocialInst = JustSocial:new()
JustSocialInst:Init()
