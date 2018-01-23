   -- Module options:

    local always_try_using_lpeg = true

    local register_global_module_table = false

    local global_module_name = 'json'


    --[==[

David Kolf's JSON module for Lua 5.1/5.2

========================================

*Version 2.4*

In the default configuration this module writes no global values, not even

the module table. Import it using

json = require ("dkjson")

In environments where `require` or a similiar function are not available

and you cannot receive the return value of the module, you can set the

option `register_global_module_table` to `true`. The module table will

then be saved in the global variable with the name given by the option

`global_module_name`.

Exported functions and values:

`json.encode (object [, state])`

--------------------------------

Create a string representing the object. `Object` can be a table,

a string, a number, a boolean, `nil`, `json.null` or any object with

a function `__tojson` in its metatable. A table can only use strings

and numbers as keys and its values have to be valid objects as

well. It raises an error for any invalid data types or reference

cycles.

`state` is an optional table with the following fields:

- `indent` 

When `indent` (a boolean) is set, the created string will contain

newlines and indentations. Otherwise it will be one long line.

- `keyorder` 

`keyorder` is an array to specify the ordering of keys in the

encoded output. If an object has keys which are not in this array

they are written after the sorted keys.

- `level` 

This is the initial level of indentation used when `indent` is

set. For each level two spaces are added. When absent it is set

to 0.

- `buffer` 

`buffer` is an array to store the strings for the result so they

can be concatenated at once. When it isn't given, the encode

function will create it temporary and will return the

concatenated result.

- `bufferlen` 

When `bufferlen` is set, it has to be the index of the last

element of `buffer`.

- `tables` 

`tables` is a set to detect reference cycles. It is created

temporary when absent. Every table that is currently processed

is used as key, the value is `true`.

When `state.buffer` was set, the return value will be `true` on

success. Without `state.buffer` the return value will be a string.

`json.decode (string [, position [, null]])`

--------------------------------------------

Decode `string` starting at `position` or at 1 if `position` was

omitted.

`null` is an optional value to be returned for null values. The

default is `nil`, but you could set it to `json.null` or any other

value.

The return values are the object or `nil`, the position of the next

character that doesn't belong to the object, and in case of errors

an error message.

Two metatables are created. Every array or object that is decoded gets

a metatable with the `__jsontype` field set to either `array` or

`object`. If you want to provide your own metatables use the syntax

json.decode (string, position, null, objectmeta, arraymeta)

To prevent the assigning of metatables pass `nil`:

json.decode (string, position, null, nil)

`<metatable>.__jsonorder`

-------------------------

`__jsonorder` can overwrite the `keyorder` for a specific table.

`<metatable>.__jsontype`

------------------------

`__jsontype` can be either `"array"` or `"object"`. This value is only

checked for empty tables. (The default for empty tables is `"array"`).

`<metatable>.__tojson (self, state)`

------------------------------------

You can provide your own `__tojson` function in a metatable. In this

function you can either add directly to the buffer and return true,

or you can return a string. On errors nil and a message should be

returned.

`json.null`

-----------

You can use this value for setting explicit `null` values.

`json.version`

--------------

Set to `"dkjson 2.4"`.

`json.quotestring (string)`

---------------------------

Quote a UTF-8 string and escape critical characters using JSON

escape sequences. This function is only necessary when you build

your own `__tojson` functions.

`json.addnewline (state)`

-------------------------

When `state.indent` is set, add a newline to `state.buffer` and spaces

according to `state.level`.

LPeg support

------------

When the local configuration variable `always_try_using_lpeg` is set,

this module tries to load LPeg to replace the `decode` function. The

speed increase is significant. You can get the LPeg module at

<http://www.inf.puc-rio.br/~roberto/lpeg/>.

When LPeg couldn't be loaded, the pure Lua functions stay active.

In case you don't want this module to require LPeg on its own,

disable the option `always_try_using_lpeg` in the options section at

the top of the module.

In this case you can later load LPeg support using

### `json.use_lpeg ()`

Require the LPeg module and replace the functions `quotestring` and

and `decode` with functions that use LPeg patterns.

This function returns the module table, so you can load the module

using:

json = require "dkjson".use_lpeg()

Alternatively you can use `pcall` so the JSON module still works when

LPeg isn't found.

json = require "dkjson"

pcall (json.use_lpeg)

### `json.using_lpeg`

This variable is set to `true` when LPeg was loaded successfully.

---------------------------------------------------------------------

Contact

-------

You can contact the author by sending an e-mail to 'david' at the

domain 'dkolf.de'.

---------------------------------------------------------------------

*Copyright (C) 2010-2013 David Heiko Kolf*

Permission is hereby granted, free of charge, to any person obtaining

a copy of this software and associated documentation files (the

"Software"), to deal in the Software without restriction, including

without limitation the rights to use, copy, modify, merge, publish,

distribute, sublicense, and/or sell copies of the Software, and to

permit persons to whom the Software is furnished to do so, subject to

the following conditions:

The above copyright notice and this permission notice shall be

included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,

EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF

MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND

NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS

BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN

ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN

CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

SOFTWARE.

<!-- This documentation can be parsed using Markdown to generate HTML.

The source code is enclosed in a HTML comment so it won't be displayed

by browsers, but it should be removed from the final HTML file as

it isn't a valid HTML comment (and wastes space).

-->

<!--]==]


-- global dependencies:

local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =

      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset

local error, require, pcall, select = error, require, pcall, select

local floor, huge = math.floor, math.huge

local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =

      string.rep, string.gsub, string.sub, string.byte, string.char,

      string.find, string.len, string.format

local strmatch = string.match

local concat = table.concat


local json = { version = "dkjson 2.4" }


if register_global_module_table then

  _G[global_module_name] = json

end


local _ENV = nil -- blocking globals in Lua 5.2


pcall (function()

  -- Enable access to blocked metatables.

  -- Don't worry, this module doesn't change anything in them.

  local debmeta = require "debug".getmetatable

  if debmeta then getmetatable = debmeta end

end)


json.null = setmetatable ({}, {

  __tojson = function () return "null" end

})


local function isarray (tbl)

  local max, n, arraylen = 0, 0, 0

  for k,v in pairs (tbl) do

    if k == 'n' and type(v) == 'number' then

      arraylen = v

      if v > max then

        max = v

      end

    else

      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then

        return false

      end

      if k > max then

        max = k

      end

      n = n + 1

    end

  end

  if max > 10 and max > arraylen and max > n * 2 then

    return false -- don't create an array with too many holes

  end

  return true, max

end


local escapecodes = {

  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",

  ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t"

}


local function escapeutf8 (uchar)

  local value = escapecodes[uchar]

  if value then

    return value

  end

  local a, b, c, d = strbyte (uchar, 1, 4)

  a, b, c, d = a or 0, b or 0, c or 0, d or 0

  if a <= 0x7f then

    value = a

  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then

    value = (a - 0xc0) * 0x40 + b - 0x80

  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then

    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80

  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then

    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80

  else

    return ""

  end

  if value <= 0xffff then

    return strformat ("\\u%.4x", value)

  elseif value <= 0x10ffff then

    -- encode as UTF-16 surrogate pair

    value = value - 0x10000

    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)

    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)

  else

    return ""

  end

end


local function fsub (str, pattern, repl)

  -- gsub always builds a new string in a buffer, even when no match

  -- exists. First using find should be more efficient when most strings

  -- don't contain the pattern.

  if strfind (str, pattern) then

    return gsub (str, pattern, repl)

  else

    return str

  end

end


local function quotestring (value)

  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js

  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)

  if strfind (value, "[\194\216\220\225\226\239]") then

    value = fsub (value, "\194[\128-\159\173]", escapeutf8)

    value = fsub (value, "\216[\128-\132]", escapeutf8)

    value = fsub (value, "\220\143", escapeutf8)

    value = fsub (value, "\225\158[\180\181]", escapeutf8)

    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)

    value = fsub (value, "\226\129[\160-\175]", escapeutf8)

    value = fsub (value, "\239\187\191", escapeutf8)

    value = fsub (value, "\239\191[\176-\191]", escapeutf8)

  end

  return "\"" .. value .. "\""

end

json.quotestring = quotestring


local function replace(str, o, n)

  local i, j = strfind (str, o, 1, true)

  if i then

    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)

  else

    return str

  end

end


-- locale independent num2str and str2num functions

local decpoint, numfilter


local function updatedecpoint ()

  decpoint = strmatch(tostring(0.5), "([^05+])")

  -- build a filter that can be used to remove group separators

  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"

end


updatedecpoint()


local function num2str (num)

  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")

end


local function str2num (str)

  local num = tonumber(replace(str, ".", decpoint))

  if not num then

    updatedecpoint()

    num = tonumber(replace(str, ".", decpoint))

  end

  return num

end


local function addnewline2 (level, buffer, buflen)

  buffer[buflen+1] = "\n"

  buffer[buflen+2] = strrep (" ", level)

  buflen = buflen + 2

  return buflen

end


function json.addnewline (state)

  if state.indent then

    state.bufferlen = addnewline2 (state.level or 0,

                           state.buffer, state.bufferlen or #(state.buffer))

  end

end


local encode2 -- forward declaration


local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder)

  local kt = type (key)

  if kt ~= 'string' and kt ~= 'number' then

    return nil, "type '" .. kt .. "' is not supported as a key by JSON."

  end

  if prev then

    buflen = buflen + 1

    buffer[buflen] = ","

  end

  if indent then

    buflen = addnewline2 (level, buffer, buflen)

  end

  buffer[buflen+1] = quotestring (key)

  buffer[buflen+2] = ":"

  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder)

end


encode2 = function (value, indent, level, buffer, buflen, tables, globalorder)

  local valtype = type (value)

  local valmeta = getmetatable (value)

  valmeta = type (valmeta) == 'table' and valmeta -- only tables

  local valtojson = valmeta and valmeta.__tojson

  if valtojson then

    if tables[value] then

      return nil, "reference cycle"

    end

    tables[value] = true

    local state = {

        indent = indent, level = level, buffer = buffer,

        bufferlen = buflen, tables = tables, keyorder = globalorder

    }

    local ret, msg = valtojson (value, state)

    if not ret then return nil, msg end

    tables[value] = nil

    buflen = state.bufferlen

    if type (ret) == 'string' then

      buflen = buflen + 1

      buffer[buflen] = ret

    end

  elseif value == nil then

    buflen = buflen + 1

    buffer[buflen] = "null"

  

