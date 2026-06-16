local function findCake()
	for slot = 1, 16 do
		local item = turtle.getItemDetail(slot)
		if item and item.name == "minecraft:cake" then
			return slot
		end
	end
	return nil
end

local function suckCakes()
	for slot = 1, 16 do
		turtle.select(slot)
		turtle.suckUp()
	end
end

local function placeCakesAround()
	for i = 1, 4 do
		local slot = findCake()
		if slot then
			turtle.select(slot)
			if not turtle.detect() then
				turtle.place()
			end
		else
			print("cake is mising!")
			break
		end
		turtle.turnRight()
	end
end

suckCakes()
placeCakesAround()
print("Done!")
