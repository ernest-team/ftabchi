redis = (loadfile "redis.lua")()
function gettabchiid()
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls')
	local last = 0
    for filename in pfile:lines() do
        if filename:match('ftabchi%-(%d+)%.lua') and tonumber(filename:match('ftabchi%-(%d+)%.lua')) >= last then
			last = tonumber(filename:match('ftabchi%-(%d+)%.lua')) + 1
			end		
    end
    return last
end
local last = gettabchiid()
io.write("Auto Detected Ftabchi ID : "..last)
io.write("\nEnter Full Sudo ID : ")
local sudo=io.read()
local text,ok = io.open("base.lua",'r'):read('*a'):gsub("FTABCHI%-ID",last)
io.open("ftabchi-"..last..".lua",'w'):write(text):close()
io.open("ftabchi-"..last..".sh",'w'):write("while true; do\n$(dirname $0)/telegram-cli-1222 -p ftabchi-"..last.." -s ftabchi-"..last..".lua\ndone"):close()
io.popen("chmod 777 tabchi-"..last..".sh")
redis:set('ftabchi:'..last..':fullsudo',sudo)
print("Done!\nNew Ftabchi Created...\nID : "..last.."\nFull Sudo : "..sudo.."\nRun : ./ftabchi-"..last..".sh\nDeveloped by: ernestteam")
