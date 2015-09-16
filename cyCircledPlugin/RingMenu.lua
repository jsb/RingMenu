local addonName = "RingMenu"

cyCircled_RingMenu = cyCircled:NewModule(addonName)

function cyCircled_RingMenu:AddonLoaded()
	self.db = cyCircled:AcquireDBNamespace(addonName)
	cyCircled:RegisterDefaults(addonName, "profile", {
		["Main"] = true,
	})
	
	self:SetupElements()
	self:OnEnable()
end

function cyCircled_RingMenu:GetElements()
	return {
		["Main"] = true,
	}
end

function cyCircled_RingMenu:SetupElements()
	self.elements = {
		["Main"] = { 
			args = {
				button = { width = 36, height = 36, },
				hotkey = false,
			},
			elements = {}, 
		},
	}
	
	for i=1, 24, 1 do
		table.insert(self.elements["Main"].elements, format("RingMenuButton%d", i))
	end
end