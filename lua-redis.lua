local redis = {

    _VERSION = 'redis-lua 2.0.4',

    _DESCRIPTION = 'A Lua client library for the redis key value storage system.',

    _COPYRIGHT = 'Copyright (C) 2009-2012 Daniele Alessandri',

}


-- The following line is used for backwards compatibility in order to keep the `Redis`

-- global module name. Using `Redis` is now deprecated so you should explicitly assign

-- the module to a local variable when requiring it: `local redis = require('redis')`.

Redis = redis


local unpack = _G.unpack or table.unpack

local network, request, response = {}, {}, {}


local defaults = {

    host = '127.0.0.1',

    port = 6379,

    tcp_nodelay = true,

    path = nil

}


local function merge_defaults(parameters)

    if parameters == nil then

        parameters = {}

    end

    for k, v in pairs(defaults) do

        if parameters[k] == nil then

            parameters[k] = defaults[k]

        end

    end

    return parameters

end


local function parse_boolean(v)

    if v == '1' or v == 'true' or v == 'TRUE' then

        return true

    elseif v == '0' or v == 'false' or v == 'FALSE' then

        return false

    else

        return nil

    end

end


local function toboolean(value) return value == 1 end


local function sort_request(client, command, key, params)

    --[[ params = {

by = 'weight_*',

get = 'object_*',

limit = { 0, 10 },

sort = 'desc',

alpha = true,

} ]]

    local query = { key }


    if params then

        if params.by then

            table.insert(query, 'BY')

            table.insert(query, params.by)

        end


        if type(params.limit) == 'table' then

            -- TODO: check for lower and upper limits

            table.insert(query, 'LIMIT')

            table.insert(query, params.limit[1])

            table.insert(query, params.limit[2])

        end


        if params.get then

            if (type(params.get) == 'table') then

                for _, getarg in pairs(params.get) do

                    table.insert(query, 'GET')

                    table.insert(query, getarg)

                end

            else

                table.insert(query, 'GET')

                table.insert(query, params.get)

            end

        end


        if params.sort then

            table.insert(query, params.sort)

        end


        if params.alpha == true then

            table.insert(query, 'ALPHA')

        end


        if params.store then

            table.insert(query, 'STORE')

            table.insert(query, params.store)

        end

    end


    request.multibulk(client, command, query)

end


local function zset_range_request(client, command, ...)

    local args, opts = {...}, { }


    if #args >= 1 and type(args[#args]) == 'table' then

        local options = table.remove(args, #args)

        if options.withscores then

            table.insert(opts, 'WITHSCORES')

        end

    end


    for _, v in pairs(opts) do table.insert(args, v) end

    request.multibulk(client, command, args)

end


local function zset_range_byscore_request(client, command, ...)

    local args, opts = {...}, { }


    if #args >= 1 and type(args[#args]) == 'table' then

        local options = table.remove(args, #args)

        if options.limit then

            table.insert(opts, 'LIMIT')

            table.insert(opts, options.limit.offset or options.limit[1])

            table.insert(opts, options.limit.count or options.limit[2])

        end

        if options.withscores then

            table.insert(opts, 'WITHSCORES')

        end

    end


    for _, v in pairs(opts) do table.insert(args, v) end

    request.multibulk(client, command, args)

end


local function zset_range_reply(reply, command, ...)

    local args = {...}

    local opts = args[4]

    if opts and (opts.withscores or string.lower(tostring(opts)) == 'withscores') then

        local new_reply = { }

        for i = 1, #reply, 2 do

            table.insert(new_reply, { reply[i], reply[i + 1] })

        end

        return new_reply

    else

        return reply

    end

end


local function zset_store_request(client, command, ...)

    local args, opts = {...}, { }


    if #args >= 1 and type(args[#args]) == 'table' then

        local options = table.remove(args, #args)

        if options.weights and type(options.weights) == 'table' then

            table.insert(opts, 'WEIGHTS')

            for _, weight in ipairs(options.weights) do

                table.insert(opts, weight)

            end

        end

        if options.aggregate then

            table.insert(opts, 'AGGREGATE')

            table.insert(opts, options.aggregate)

        end

    end


    for _, v in pairs(opts) do table.insert(args, v) end

    request.multibulk(client, command, args)

end


local function mset_filter_args(client, command, ...)

    local args, arguments = {...}, {}

    if (#args == 1 and type(args[1]) == 'table') then

        for k,v in pairs(args[1]) do

            table.insert(arguments, k)

            table.insert(arguments, v)

        end

    else

        arguments = args

    end

    request.multibulk(client, command, arguments)

end


local function hash_multi_request_builder(builder_callback)

    return function(client, command, ...)

        local args, arguments = {...}, { }

        if #args == 2 then

            table.insert(arguments, args[1])

            for k, v in pairs(args[2]) do

                builder_callback(arguments, k, v)

            end

        else

            arguments = args

        end

        request.multibulk(client, command, arguments)

    end

end


local function parse_info(response)

    local info = {}

    local current = info


    response:gsub('([^\r\n]*)\r\n', function(kv)

        if kv == '' then return end


        local section = kv:match('^# (%w+)$')

        if section then

            current = {}

            info[section:lower()] = current

            return

        end


        local k,v = kv:match(('([^:]*):([^:]*)'):rep(1))

        if k:match('db%d+') then

            current[k] = {}

            v:gsub(',', function(dbkv)

                local dbk,dbv = kv:match('([^:]*)=([^:]*)')

                current[k][dbk] = dbv

            end)

        else

            current[k] = v

        end

    end)


    return info

end


local function load_methods(proto, commands)

    local client = setmetatable ({}, getmetatable(proto))


    for cmd, fn in pairs(commands) do

        if type(fn) ~= 'function' then

            redis.error('invalid type for command ' .. cmd .. '(must be a function)')

        end

        client[cmd] = fn

    end


    for i, v in pairs(proto) do

        client[i] = v

    end


    return client

end


local function create_client(proto, client_socket, commands)

    local client = load_methods(proto, commands)

    client.error = redis.error

    client.network = {

        socket = client_socket,

        read = network.read,

        write = network.write,

    }

    client.requests = {

        multibulk = request.multibulk,

    }

    return client

end


-- ############################################################################


function network.write(client, buffer)

    local _, err = client.network.socket:send(buffer)

    if err then client.error(err) end

end


function network.read(client, len)

    if len == nil then len = '*l' end

    local line, err = client.network.socket:receive(len)

    if not err then return line else client.error('connection error: ' .. err) end

end


-- ############################################################################


function response.read(client)

    local payload = client.network.read(client)

    local prefix, data = payload:sub(1, -#payload), payload:sub(2)


    -- status reply

    if prefix == '+' then

        if data == 'OK' then

            return true

        elseif data == 'QUEUED' then

            return { queued = true }

        else

            return data

        end


   -- error reply

    elseif prefix == '-' then

        return client.error('redis error: ' .. data)


   -- integer reply

    elseif prefix == ':' then

        local number = tonumber(data)


        if not number then

            if res == 'nil' then

                return nil

            end

            client.error('cannot parse '..res..' as a numeric response.')

        end


        return number


   -- bulk reply

    elseif prefix == '$' then

        local length = tonumber(data)


        if not length then

            client.error('cannot parse ' .. length .. ' as data length')

        end


        if length == -1 then

            return nil

        end


        local nextchunk = client.network.read(client, length + 2)


        return nextchunk:sub(1, -3)


   -- multibulk reply

    elseif prefix == '*' then

        local count = tonumber(data)


        if count == -1 then

            return nil

        end


        local list = {}

        if count > 0 then

            local reader = response.read

            for i = 1, count do

                list[i] = reader(client)

            end

        end

        return list


   -- unknown type of reply

    else

        return client.error('unknown response prefix: ' .. prefix)

    end

end


-- ############################################################################


function request.raw(client, buffer)

    local bufferType = type(buffer)


    if bufferType == 'table' then

        client.network.write(client, table.concat(buffer))

    elseif bufferType == 'string' then

        client.network.write(client, buffer)

    else

        client.error('argument error: ' .. bufferType)

    end

end


function request.multibulk(client, command, ...)

    local args = {...}

    local argsn = #args

    local buffer = { true, true }


    if argsn == 1 and type(args[1]) == 'table' then

        argsn, args = #args[1], args[1]

    end


    buffer[1] = '*' .. tostring(argsn + 1) .. "\r\n"

    buffer[2] = '$' .. #command .. "\r\n" .. command .. "\r\n"


    local table_insert = table.insert

    for _, argument in pairs(args) do

        local s_argument = tostring(argument)

        table_insert(buffer, '$' .. #s_argument .. "\r\n" .. s_argument .. "\r\n")

    end


