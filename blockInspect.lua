-- Турель-черепашка: огляд блоку та вивід на монітор
local monitor = peripheral.find("monitor")

if not monitor then
	error("Монітор не знайдено! Підключіть монітор до черепашки.")
end

monitor.setTextScale(0.5)

local function clearMonitor()
	monitor.clear()
	monitor.setCursorPos(1, 1)
end

local function printTable(t, indent, line)
	indent = indent or 0
	for key, value in pairs(t) do
		local prefix = string.rep("  ", indent)
		if type(value) == "table" then
			monitor.setCursorPos(1, line[1])
			monitor.write(prefix .. tostring(key) .. ":")
			line[1] = line[1] + 1
			printTable(value, indent + 1, line)
		else
			monitor.setCursorPos(1, line[1])
			monitor.write(prefix .. tostring(key) .. " = " .. tostring(value))
			line[1] = line[1] + 1
		end
	end
end

local function inspectAndShow()
	clearMonitor()
	local success, data = turtle.inspect() -- дивиться вперед

	if success then
		local line = { 1 }
		monitor.setCursorPos(1, line[1])
		monitor.write("=== Інформація про блок ===")
		line[1] = line[1] + 2
		printTable(data, 0, line)
	else
		monitor.setCursorPos(1, 1)
		monitor.write("Перед черепашкою немає блоку.")
	end
end

inspectAndShow()
