local FUEL_SLOT = 1
local NETHERRACK_NAME = "minecraft:netherrack"

local NETHER_ORES = {
	["minecraft:nether_quartz_ore"] = true,
	["minecraft:nether_gold_ore"] = true,
	["minecraft:ancient_debris"] = true,
	["minecraft:gilded_blackstone"] = true,
}

local startX, startY, startZ = 0, 0, 0
local posX, posZ = 0, 0
local facing = 0

local function checkFuel()
	if turtle.getFuelLevel() == "unlimited" then
		return
	end
	if turtle.getFuelLevel() < 50 then
		turtle.select(FUEL_SLOT)
		turtle.refuel()
	end
end

local function isInventoryFull()
	for slot = 2, 16 do
		if turtle.getItemCount(slot) == 0 then
			return false
		end
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

local function processBlock(direction)
	local inspect, dig, place, detect
	if direction == "up" then
		inspect, dig, place, detect = turtle.inspectUp, turtle.digUp, turtle.placeUp, turtle.detectUp
	else
		inspect, dig, place, detect = turtle.inspectDown, turtle.digDown, turtle.placeDown, turtle.detectDown
	end

	local success, data = inspect()

	if success then
		if NETHER_ORES[data.name] then
			dig()
		end
	else
		if selectNetherrack() then
			place()
		end
	end
end

local function processUpDown()
	processBlock("up")
	processBlock("down")
end

local function forward()
	checkFuel()
	while not turtle.forward() do
		turtle.dig()
		sleep(0.2)
	end
	if facing == 0 then
		posZ = posZ + 1
	elseif facing == 1 then
		posX = posX + 1
	elseif facing == 2 then
		posZ = posZ - 1
	elseif facing == 3 then
		posX = posX - 1
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

local function returnAndUnload()
	if posX > 0 then
		faceDirection(3)
		for i = 1, posX do
			forward()
		end
	elseif posX < 0 then
		faceDirection(1)
		for i = 1, -posX do
			forward()
		end
	end

	if posZ > 0 then
		faceDirection(2)
		for i = 1, posZ do
			forward()
		end
	elseif posZ < 0 then
		faceDirection(0)
		for i = 1, -posZ do
			forward()
		end
	end

	for slot = 2, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name ~= NETHERRACK_NAME then
			turtle.select(slot)
			turtle.dropDown()
		end
	end
	turtle.select(FUEL_SLOT)
	print("Done.")
end

local SIZE = 11

local function mineArea()
	for row = 1, SIZE do
		for col = 1, SIZE do
			processUpDown()

			if isInventoryFull() then
				local savedX, savedZ, savedFacing = posX, posZ, facing
				returnAndUnload()
				if savedX > 0 then
					faceDirection(1)
					for i = 1, savedX do
						forward()
					end
				end
				if savedZ > 0 then
					faceDirection(0)
					for i = 1, savedZ do
						forward()
					end
				end
				faceDirection(savedFacing)
			end

			if col < SIZE then
				forward()
			end
		end

		if row < SIZE then
			if row % 2 == 1 then
				turnRight()
				forward()
				turnRight()
			else
				turnLeft()
				forward()
				turnLeft()
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
