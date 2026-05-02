zapTimer = zapTimer or {}

local hashTable = {}
local timers = {}

function zapTimer.Timers()
	return timers
end

function zapTimer.Create(hash, delay, reps, func)
	if not hash then
		error("Invalid timer name: "..tostring(hash),2)
	end

	if type(delay) ~= "number" or delay < 0 then
		error("Invalid timer delay: "..tostring(delay),2)
	end
	if type(reps) ~= "number" or reps < 0 or math.floor(reps) ~= reps then
		error("Invalid timer reps: "..tostring(reps),2)
	end
	if type(func) ~= "function" and not (debug.getmetatable(func) and debug.getmetatable(func).__call) then
		error("Invalid timer function: "..tostring(func),2)
	end

	local id = #timers + 1

	hash = tostring(hash)

	hashTable[hash] = id

	timers[id] = {
		hash = hash,
		delay = delay,
		reps = reps == 0 and -1 or reps,
		func = func,
		on = false,
		lastExec = 0,
	}
	
	zapTimer.Start(id)
end

function zapTimer.Simple(delay, func)
	if type(delay) ~= "number" or delay < 0 then
		error("Invalid timer delay: "..tostring(delay),2)
	end
	if type(func) ~= "function" and not (debug.getmetatable(func) and debug.getmetatable(func).__call) then
		error("Invalid timer function: "..tostring(func),2)
	end

	local id = #timers + 1

	timers[id] = {
		id = id,
		delay = delay,
		reps = 1,
		func = func,
		on = false,
		lastExec = 0,
	}
	
	zapTimer.Start(id)

	return id
end


function zapTimer.Start(id)
	local t = timers[id]
	if not t then
		error("Tried to start nonexistant timer: "..tostring(hash),2)
	end

	t.on = true
	t.timeDiff = nil
	t.lastExec = CurTime()
	return true
end

function zapTimer.Stop(id)
	local t = timers[id]
	if not t then return false end

	t.on = false
	t.timeDiff = nil
	return true
end

function zapTimer.Pause(hash)
	local t = hashTable[hash]
	if not t then return false end

	t = timers[t]

	t.on = false
	t.timeDiff = CurTime() - t.lastExec
	return true
end

function zapTimer.UnPause(hash)
	local t = hashTable[hash]
	if not t then
		error("Tried to unpause nonexistant timer: "..tostring(id),2)
	end

	t = timers[t]

	if not t.timeDiff then
		error("Tried to unpause nonpaused timer: "..tostring(id),2)
	end
	
	t.on = true
	t.lastExec = CurTime() - t.timeDiff
	t.timeDiff = nil
	return true
end

function zapTimer.Adjust(hash, delay, reps, func)
	local t = hashTable[hash]
	if not t then
		error("Tried to adjust nonexistant timer: "..tostring(id),2)
	end
	if type(delay) ~= "number" or delay < 0 then
		error("Invalid timer delay: "..tostring(delay),2)
	end
	if type(reps) ~= "number" or reps < 0 or math.floor(reps) ~= reps then
		error("Invalid timer reps: "..tostring(reps),2)
	end

	t = timers[t]

	t.delay = delay
	t.reps = reps

	if func then
		if type(func) ~= "function" and not (debug.getmetatable(func) and debug.getmetatable(func).__call) then
			error("Invalid timer function: "..tostring(func),2)
		end
		t.func = func
	end
	return true
end

local function fastTimerRemove(index)
	local tbl = timers
    local c = #tbl

    local tmr = tbl[index]

	if index >= c or c == 1 then
		tbl[index] = nil
    else
    	local hash = tbl[c].hash

        tbl[index] = tbl[c]
        tbl[c] = nil

        hashTable[hash] = index
    end

    if tmr.hash then hashTable[tmr.hash] = nil end
end

function zapTimer.Destroy(hash)

	if type(hash) ~= "string" then error("Timer name must be string!") end

	local id = hashTable[hash]

	if not id then error("Invalid timer "..tostring(delay),2) end

	fastTimerRemove(id)
end
zapTimer.Remove = zapTimer.Destroy

local cache_pcall = pcall

local function zapTimerCheck()
	local t = CurTime()

	for i=1, #timers do
		local tmr = timers[i]

		if tmr == nil then 
			continue end

		local timerID = i

		if tmr.lastExec + tmr.delay <= t and tmr.on then
			local ok, err = cache_pcall(tmr.func)

			if not ok then
				ErrorNoHalt(err)

				fastTimerRemove(timerID)
			else
				tmr.lastExec = t + tmr.delay
				tmr.reps = tmr.reps - 1
				if tmr.reps == 0 then
					fastTimerRemove(timerID)
				end
			end
		end
	end
end

hook.Add("Think", "CheckZapTimers", zapTimerCheck)
