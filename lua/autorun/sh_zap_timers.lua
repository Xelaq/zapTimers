local function xpcall_callback(err)
	return debug.traceback(tostring(err),2)
end

zapTimer = zapTimer or {}

local timers = {}

local function zapTimerStart(id)
	local t = timers[id]
	if not t then
		error("Tried to start nonexistant timer: "..tostring(id),2)
	end
	t.on = true
	t.timeDiff = nil
	t.lastExec = CurTime()
	return true
end


function zapTimer.Create(delay, reps, func)
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

	timers[id] = {
		delay = delay,
		reps = reps == 0 and -1 or reps,
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
		error("Tried to start nonexistant timer: "..tostring(id),2)
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

function zapTimer.Pause(id)
	local t = timers[id]
	if not t then return false end
	t.on = false
	t.timeDiff = CurTime() - t.lastExec
	return true
end

function zapTimer.UnPause(id)
	local t = timers[id]
	if not t or not t.timeDiff then
		error("Tried to unpause nonexistant timer: "..tostring(id),2)
	end
	if not t.timeDiff then
		error("Tried to unpause nonpaused timer: "..tostring(id),2)
	end
	
	t.on = true
	t.lastExec = CurTime() - t.timeDiff
	t.timeDiff = nil
	return true
end

function zapTimer.Adjust(id, delay, reps, func)
	local t = timers[id]
	if not t or not t.timeDiff then
		error("Tried to adjust nonexistant timer: "..tostring(id),2)
	end
	if type(delay) ~= "number" or delay < 0 then
		error("Invalid timer delay: "..tostring(delay),2)
	end
	if type(reps) ~= "number" or reps < 0 or math.floor(reps) ~= reps then
		error("Invalid timer reps: "..tostring(reps),2)
	end

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

function zapTimer.Destroy(id)
	timers[id] = nil
end
zapTimer.Remove = zapTimer.Destroy

function zapTimer.Simple(delay, func)
	if type(delay) ~= "number" or delay < 0 then
		error("Invalid timer delay: "..tostring(delay),2)
	end
	if type(func) ~= "function" and not (debug.getmetatable(func) and debug.getmetatable(func).__call) then
		error("Invalid timer function: "..tostring(func),2)
	end

	local id = #timers + 1

	timers[id] = {
		delay = delay,
		reps = 1,
		func = func,
		on = false,
		lastExec = 0,
	}
	
	zapTimer.Start(id)

	return id
end

local tblCount = table.Count

function zapTimer.Timers()
	return timers
end

function zapTimer.Check()
	local t = CurTime()

	--#	5.0430000374035e-06
	--table.Count	7.3619999966468e-06
	--table.Count (cached)	6.6449999940232e-06

	for i=1, #timers do
		local tmr = timers[i]

		if not tmr then continue end

		if tmr.lastExec + tmr.delay <= t then
			local ok, err = xpcall(tmr.func, xpcall_callback)
			if not ok then
				ErrorNoHalt(err)

				--table.remove	1.1521410999103e-05
				--table[] = nil	1.1539101998114e-05

				table.remove(timers, i)
			else
				tmr.lastExec = t
				tmr.reps = tmr.reps - 1
				if tmr.reps == 0 then

					table.remove(timers, i)
				end
			end
		end
	end
end

function zapTimer.Check2()
	local t = CurTime()

	for i=1, #timers do
		local tmr = timers[i]
		
		if tmr.lastExec + tmr.delay <= t then
			local ok, err = xpcall(tmr.func, xpcall_callback)
			if not ok then
				ErrorNoHalt(err)

				--table.remove	1.1521410999103e-05
				--table[] = nil	1.1539101998114e-05

				table.remove(timers, i)
			else
				tmr.lastExec = t
				tmr.reps = tmr.reps - 1
				if tmr.reps == 0 then
					table.remove(timers, i)
				end
			end
		end
		
	end
end

--hook.Add("Think", "CheckTimers", zapTimer.Check)