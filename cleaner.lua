redis = (loadfile "redis.lua")()

io.write("Enter Tabchi ID : ")

local last = io.read()

io.popen('rm -rf ~/.telegram-cli/tabchi-'..last..' tabchi-'..last..'.lua tabchi-'..last..'.sh tabchi_'..last..'_logs.txt')

redis:del('tabchi:'..last..':*')

print("Done!\nAll Data/Files Of Tabchi Deleted\nTabchi ID : "..last)

