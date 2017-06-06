if CLIENT then
	require("hook")
	require("concommand")
	require("timer")
	
	local olde = RunConsoleCommand
	local getHooks = hook.GetTable
	local isstr = isstring
	local tblHasVal = table.HasValue
	local tblInsert = table.insert
	local cvarCallback = cvars.AddChangeCallback
	local netStart = net.Start
	local netTable = net.WriteTable
	local netSend = net.SendToServer
	local getcvar = GetConVarNumber
	
	local datcc = function( ... )
		olde( ... )
	end
	
	local function formatHooks( tbl )
		for k,v in pairs(getHooks()) do
			for l, m in pairs(v) do
				if isstr(k) and isstr(l) then
					local temp = k..": "..l
					tblInsert(tbl, temp)
				end
			end
		end
	end
	
	hook.Add("InitPostEntity", "initcheckvars", function()
		local tmptbl = { getcvar("sv_cheats"), getcvar("host_timescale"), getcvar("sv_allowcslua") }
		formatHooks(tmptbl)
		
		netStart("woppitydop")
		netTable(tmptbl)
		netSend()
		
		timer.Create("ar_cvarcheck", 20, 0, function()
			local tmptbl = { getcvar("sv_cheats"), getcvar("host_timescale"), getcvar("sv_allowcslua") }
			formatHooks(tmptbl)
		
			netStart("woppitydop")
			netTable(tmptbl)
			netSend()
		end)
	end)
end