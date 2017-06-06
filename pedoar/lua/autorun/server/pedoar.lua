AddCSLuaFile("lua/autorun/client/waffles.lua")

util.AddNetworkString("woppitydop")
if not file.Exists("ar_hookReports.txt", "DATA") then
	file.Write("ar_hookReports.txt", "Received non-standard hooks:")
end

local VerifiedPlayers = {}
local whitelist = {	}

local function checkIfVerified(p)
	for k,v in pairs(VerifiedPlayers) do
		if v[1] == p then
			return k
		end
	end
	return false
end

local function notifyAdmins(p, msg, logging)
	for k,v in pairs(player.GetAll()) do
		if v:IsAdmin() then
			evolve:Notify(v, evolve.colors.red, p:Nick(), " [", p:SteamID(), "] "..msg)
		end
	end
	if logging then
		file.Append("ar_hookReports.txt", "\n"..p:Nick().." ["..p:SteamID().."] "..msg)
	end
end

timer.Create("verify_Players", 21, 0, function()
	local curtime = RealTime()
	local removeme = {}
	
	for k,v in pairs(VerifiedPlayers) do
		if IsValid(v[1]) and ( curtime - v[2] ) > 25 then
			notifyAdmins(v[1], "Has not sent an update for "..math.floor( curtime - v[2] ) .." seconds.", false)
		end
	end
end )

function test(len, p)
	if not IsValid(p) then return end
	if p:IsPlayer() and not p:IsBot() then
		local ind = checkIfVerified(p)
		if ind == false then
			table.insert(VerifiedPlayers, { p, RealTime() } )
			//MsgN("Creating new verified record")
		else
			VerifiedPlayers[ind] = { p, RealTime() }
			//MsgN("Updating players last verified")
		end
	end

	local stuff = net.ReadTable()
	local vars = { "sv_cheats", "host_timescale", "sv_allowcslua" }
	
	local sentinel = 1
	for k,v in pairs(vars) do
		if GetConVar(vars[sentinel]):GetInt() != stuff[sentinel] then
			//evolve:Ban(p:UniqueID(), 0, "Forced var "..vars[sentinel], 0)

			notifyAdmins(p, "Has "..vars[sentinel].." forced to "..stuff[sentinel], true)
		end
		sentinel = sentinel + 1
	end
	
	/* local dump = ""
	for k,v in pairs(stuff) do
		dump = dump.."\n".."\""..v.."\""..","
	end
	file.Write("blarg.txt", dump) */
	
	local hookcount = #stuff - sentinel
	if ( hookcount < 70 )  then
		notifyAdmins(p, "Reports an unusual hook count of ".. hookcount ..".", true)
	end
	
	local oddHooks = {}
	
	local bad = false
	for k,v in pairs(stuff) do
		if k >= sentinel then
			if not table.HasValue(whitelist, v) then
				table.insert(oddHooks, v)
			end
		end
	end
	
	if oddHooks[1] != nil then
		notifyAdmins(p, "Reported unknown hooks, printed to console.", false)
		for k,v in pairs(player.GetAll()) do
			if v:IsAdmin() then
				v:PrintMessage(HUD_PRINTCONSOLE, p:Nick().. "[" ..p:SteamID().. "] reported hooks")
			end
		end
		file.Append("ar_hookReports.txt", "\n"..p:Nick().." ["..p:SteamID().."] reported hooks")
		for _, hook in pairs(oddHooks) do
			for k,v in pairs(player.GetAll()) do
				if v:IsAdmin() then
					v:PrintMessage(HUD_PRINTCONSOLE, "     ".. hook)
				end
			end
			file.Append("ar_hookReports.txt", "\n      "..hook)
		end
	end	
end
net.Receive("woppitydop", test)

hook.Add("PlayerInitialSpawn" , "InitAR" , function(p)
	timer.Simple(20 , function(p)
		if not IsValid(p) then return end
		if p:IsPlayer() and not p:IsBot() then
			if checkIfVerified(p) == false then
				p:Kick("Did not initialize.")
			end
		end
	end , p )
end )