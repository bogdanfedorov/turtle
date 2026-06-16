local FUEL_SLOT = 1
local NETHERRACK_NAME = "minecraft:netherrack"

local NETHER_ORES = {
	["minecraft:nether_quartz_ore"] = true,
	["minecraft:nether_gold_ore"] = true,
	["minecraft:ancient_debris"] = true,
	["minecraft:gilded_blackstone"] = true,
}

local posX, posZ = 0, 0
local facing = 0

local function checkFuel()
	if turtle.getFuelLevel() == "unlimited" then return end
	if turtle.getFuelLevel() < 50 then
		turtle.select(FUEL_SLOT)
		turtle.refuel()
	end
end

local function isInventoryFull()
	for slot = 2, 16 do
		if turtle.getItemCount(slot) == 0 then return false end
	end
	return true
end

local function selectNetherrack()
	for slot = 1, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name == NETHERRACK_NAME then
			turtle.select(slot)
			return true
		end
	end
	return false
end

local function countNetherrack()
	local count = 0
	for slot = 1, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name == NETHERRACK_NAME then
			count = count + item.count
		end
	end
	return count
end

local function forward()
	checkFuel()
	while not turtle.forward() do
		turtle.dig()
		sleep(0.2)
	end
	if facing == 0 then posZ = posZ + 1
	elseif facing == 1 then posX = posX + 1
	elseif facing == 2 then posZ = posZ - 1
	elseif facing == 3 then posX = posX - 1
	end
end

local function turnRight()
	turtle.turnRight()
	facing = (facing + 1) % 4
end

local function turnLeft()
	turtle.turnLeft()
	facing = (facing + 3) % 4
end

local function faceDirection(target)
	while facing ~= target do
		turnRight()
	end
end

local function goHome()
	if posX > 0 then
		faceDirection(3)
		for i = 1, posX do forward() end
	elseif posX < 0 then
		faceDirection(1)
		for i = 1, -posX do forward() end
	end
	if posZ > 0 then
		faceDirection(2)
		for i = 1, posZ do forward() end
	elseif posZ < 0 then
		faceDirection(0)
		for i = 1, -posZ do forward() end
	end
end

local function returnToPosition(targetX, targetZ, targetFacing)
	if targetX > 0 then
		faceDirection(1)
		for i = 1, targetX do forward() end
	elseif targetX < 0 then
		faceDirection(3)
		for i = 1, -targetX do forward() end
	end
	if targetZ > 0 then
		faceDirection(0)
		for i = 1, targetZ do forward() end
	elseif targetZ < 0 then
		faceDirection(2)
		for i = 1, -targetZ do forward() end
	end
	faceDirection(targetFacing)
end

local function restockNetherrack()
	local savedX, savedZ, savedFacing = posX, posZ, facing
	print("No netherrack — restocking...")
	goHome()

	-- Grab up to 4 stacks (256) of netherrack from chest below
	local attempts = 0
	while countNetherrack() < 256 and attempts < 20 do
		if not turtle.suckDown(64) then break end
		attempts = attempts + 1
	end

	-- Drop back anything that isn't netherrack (keep fuel slot)
	for slot = 2, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name ~= NETHERRACK_NAME then
			turtle.select(slot)
			turtle.dropDown()
		end
	end

	turtle.select(FUEL_SLOT)
	print("Returning to work...")
	returnToPosition(savedX, savedZ, savedFacing)
end

local function placeNetherrack(place)
	if not selectNetherrack() then
		restockNetherrack()
	end
	if selectNetherrack() then
		place()
	end
end

local function processBlock(direction)
	local inspect, dig, place
	if direction == "up" then
		inspect, dig, place = turtle.inspectUp, turtle.digUp, turtle.placeUp
	else
		inspect, dig, place = turtle.inspectDown, turtle.digDown, turtle.placeDown
	end

	local success, data = inspect()

	if success then
		if NETHER_ORES[data.name] then
			dig()
			placeNetherrack(place)
		end
	else
		placeNetherrack(place)
	end
end

local function processUpDown()
	processBlock("up")
	processBlock("down")
end

local function returnAndUnload()
	goHome()
	for slot = 2, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name ~= NETHERRACK_NAME then
			turtle.select(slot)
			turtle.dropDown()
		end
	end
	turtle.select(FUEL_SLOT)
	print("Unloaded.")
end

local SIZE = 11

local function mineArea()
	for row = 1, SIZE do
		for col = 1, SIZE do
			processUpDown()

			if isInventoryFull() then
				local savedX, savedZ, savedFacing = posX, posZ, facing
				returnAndUnload()
				returnToPosition(savedX, savedZ, savedFacing)
			end

			if col < SIZE then
				forward()
			end
		end

		if row < SIZE then
			if row % 2 == 1 then
				turnLeft()
				forward()
				turnLeft()
			else
				turnRight()
				forward()
				turnRight()
			end
		end
	end
end

turtle.select(FUEL_SLOT)
checkFuel()
mineArea()

returnAndUnload()
faceDirection(0)
print("All Done!")
