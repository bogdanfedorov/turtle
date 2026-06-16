local FUEL_SLOT = 1
local NETHERRACK_NAME = "minecraft:netherrack"
local SIZE = 11

local NETHER_ORES = {
	["minecraft:nether_quartz_ore"] = true,
	["minecraft:nether_gold_ore"] = true,
	["minecraft:ancient_debris"] = true,
	["minecraft:gilded_blackstone"] = true,
}

local posX, posY, posZ = 0, 0, 0
local facing = 0
local running = true

-- ─── Movement ────────────────────────────────────────────────────────────────

local function checkFuel()
	if turtle.getFuelLevel() == "unlimited" then return end
	if turtle.getFuelLevel() < 50 then
		turtle.select(FUEL_SLOT)
		turtle.refuel()
	end
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

local function up()
	checkFuel()
	while not turtle.up() do
		turtle.digUp()
		sleep(0.2)
	end
	posY = posY + 1
end

local function down()
	checkFuel()
	while not turtle.down() do
		turtle.digDown()
		sleep(0.2)
	end
	posY = posY - 1
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

-- ─── Inventory ───────────────────────────────────────────────────────────────

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

-- ─── Navigation ──────────────────────────────────────────────────────────────

-- Navigate to (0, 0, 0). Y first so XZ travel happens at ground level.
local function goHome()
	if posY > 0 then
		for i = 1, posY do down() end
	elseif posY < 0 then
		for i = 1, -posY do up() end
	end
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

-- Navigate from (0,0,0) to saved position. XZ at ground level, then Y up.
local function returnToPosition(targetX, targetY, targetZ, targetFacing)
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
	if targetY > 0 then
		for i = 1, targetY do up() end
	elseif targetY < 0 then
		for i = 1, -targetY do down() end
	end
	faceDirection(targetFacing)
end

-- ─── Restock & Unload ────────────────────────────────────────────────────────

local function restockNetherrack()
	local savedX, savedY, savedZ, savedFacing = posX, posY, posZ, facing
	print("No netherrack - going to restock...")
	goHome()

	-- Grab up to 4 stacks from chest below
	local attempts = 0
	while countNetherrack() < 256 and attempts < 20 do
		if not turtle.suckDown(64) then break end
		attempts = attempts + 1
	end

	-- Drop back anything accidentally grabbed that isn't netherrack
	for slot = 2, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name ~= NETHERRACK_NAME then
			turtle.select(slot)
			turtle.dropDown()
		end
	end

	turtle.select(FUEL_SLOT)

	-- Stop only if no netherrack anywhere (inventory + chest both empty)
	if countNetherrack() == 0 then
		print("No netherrack in inventory or chest. Stopping.")
		running = false
		return
	end

	print("Restocked. Returning to work...")
	returnToPosition(savedX, savedY, savedZ, savedFacing)
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
	-- Stop only if inventory still full after unloading (chest is also full)
	if isInventoryFull() then
		print("Inventory and chest are both full. Stopping.")
		running = false
	end
	turtle.select(FUEL_SLOT)
end

-- ─── Block Processing ────────────────────────────────────────────────────────

local function placeNetherrack(place)
	if not selectNetherrack() then
		restockNetherrack()
		if not running then return end
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
	if not running then return end
	processBlock("up")
	if not running then return end
	processBlock("down")
end

local function handleFullInventory()
	if not isInventoryFull() then return end
	local savedX, savedY, savedZ, savedFacing = posX, posY, posZ, facing
	returnAndUnload()
	if not running then return end
	returnToPosition(savedX, savedY, savedZ, savedFacing)
end

-- ─── Mining Patterns ─────────────────────────────────────────────────────────

-- Floor 1: left-first serpentine starting north.
-- Ends at posX=-10, posZ=10, facing=0.
local function mineArea()
	for row = 1, SIZE do
		for col = 1, SIZE do
			if not running then return end
			processUpDown()
			if not running then return end
			handleFullInventory()
			if not running then return end
			if col < SIZE then forward() end
		end
		if not running then return end
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

-- Floor 2: reverse serpentine starting south.
-- Starts at posX=-10, posZ=10, ends at posX=0, posZ=0.
-- Odd rows go south (turnLeft→east), even rows go north (turnRight→east).
local function mineAreaReverse()
	faceDirection(2) -- start going south
	for row = 1, SIZE do
		for col = 1, SIZE do
			if not running then return end
			processUpDown()
			if not running then return end
			handleFullInventory()
			if not running then return end
			if col < SIZE then forward() end
		end
		if not running then return end
		if row < SIZE then
			if row % 2 == 1 then
				turnLeft()  -- east (from south)
				forward()
				turnLeft()  -- north
			else
				turnRight() -- east (from north)
				forward()
				turnRight() -- south
			end
		end
	end
end

-- ─── Main ────────────────────────────────────────────────────────────────────

turtle.select(FUEL_SLOT)
checkFuel()

-- Floor 1
mineArea()

-- Floor 2: 3 up, reverse snake back to (0,0), 3 down
if running then
	print("Floor 1 done. Going to floor 2...")
	for i = 1, 3 do up() end
	mineAreaReverse()
	if running then
		for i = 1, 3 do down() end
	end
end

-- Final unload at chest
returnAndUnload()
faceDirection(0)
print("All Done!")
