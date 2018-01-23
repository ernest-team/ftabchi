--[[

This program is free software; you can redistribute it and/or modify

it under the terms of the GNU General Public License as published by

the Free Software Foundation; either version 2 of the License, or

(at your option) any later version.

This program is distributed in the hope that it will be useful,

but WITHOUT ANY WARRANTY; without even the implied warranty of

MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the

GNU General Public License for more details.

You should have received a copy of the GNU General Public License

along with this program; if not, write to the Free Software

Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,

MA 02110-1301, USA.

]]--


-- Vector example form is like this: {[0] = v} or {v1, v2, v3, [0] = v}

-- If false or true crashed your telegram-cli, try to change true to 1 and false to 0


-- Main Bot Framework

local M = {}


-- @chat_id = user, group, channel, and broadcast

-- @group_id = normal group

-- @channel_id = channel and broadcast

local function getChatId(chat_id)

  local chat = {}

  local chat_id = tostring(chat_id)


  if chat_id:match('^-100') then

    local channel_id = chat_id:gsub('-100', '')

    chat = {ID = channel_id, type = 'channel'}

  else

    local group_id = chat_id:gsub('-', '')

    chat = {ID = group_id, type = 'group'}

  end


  return chat

end


local function getInputMessageContent(file, filetype, caption)

  if file:match('/') or file:match('.') then

    infile = {ID = "InputFileLocal", path_ = file}

  elseif file:match('^%d+$') then

    infile = {ID = "InputFileId", id_ = file}

  else

    infile = {ID = "InputFilePersistentId", persistent_id_ = file}

  end


  local inmsg = {}

  local filetype = filetype:lower()


  if filetype == 'animation' then

    inmsg = {ID = "InputMessageAnimation", animation_ = infile, caption_ = caption}

  elseif filetype == 'audio' then

    inmsg = {ID = "InputMessageAudio", audio_ = infile, caption_ = caption}

  elseif filetype == 'document' then

    inmsg = {ID = "InputMessageDocument", document_ = infile, caption_ = caption}

  elseif filetype == 'photo' then

    inmsg = {ID = "InputMessagePhoto", photo_ = infile, caption_ = caption}

  elseif filetype == 'sticker' then

    inmsg = {ID = "InputMessageSticker", sticker_ = infile, caption_ = caption}

  elseif filetype == 'video' then

    inmsg = {ID = "InputMessageVideo", video_ = infile, caption_ = caption}

  elseif filetype == 'voice' then

    inmsg = {ID = "InputMessageVoice", voice_ = infile, caption_ = caption}

  end


  return inmsg

end


-- User can send bold, italic, and monospace text uses HTML or Markdown format.

local function getParseMode(parse_mode)

  if parse_mode then

    local mode = parse_mode:lower()


    if mode == 'markdown' or mode == 'md' then

      P = {ID = "TextParseModeMarkdown"}

    elseif mode == 'html' then

      P = {ID = "TextParseModeHTML"}

    end

  end


  return P

end


-- Returns current authorization state, offline request

local function getAuthState()

  tdcli_function ({

    ID = "GetAuthState",

  }, dl_cb, nil)

end


M.getAuthState = getAuthState


-- Sets user's phone number and sends authentication code to the user.

-- Works only when authGetState returns authStateWaitPhoneNumber.

-- If phone number is not recognized or another error has happened, returns an error. Otherwise returns authStateWaitCode

-- @phone_number User's phone number in any reasonable format

-- @allow_flash_call Pass True, if code can be sent via flash call to the specified phone number

-- @is_current_phone_number Pass true, if the phone number is used on the current device. Ignored if allow_flash_call is False

local function setAuthPhoneNumber(phone_number, allow_flash_call, is_current_phone_number)

  tdcli_function ({

    ID = "SetAuthPhoneNumber",

    phone_number_ = phone_number,

    allow_flash_call_ = allow_flash_call,

    is_current_phone_number_ = is_current_phone_number

  }, dl_cb, nil)

end


M.setAuthPhoneNumber = setAuthPhoneNumber


-- Resends authentication code to the user.

-- Works only when authGetState returns authStateWaitCode and next_code_type of result is not null.

-- Returns authStateWaitCode on success

local function resendAuthCode()

  tdcli_function ({

    ID = "ResendAuthCode",

  }, dl_cb, nil)

end


M.resendAuthCode = resendAuthCode


-- Checks authentication code.

-- Works only when authGetState returns authStateWaitCode.

-- Returns authStateWaitPassword or authStateOk on success

-- @code Verification code from SMS, Telegram message, voice call or flash call

-- @first_name User first name, if user is yet not registered, 1-255 characters @last_name Optional user last name, if user is yet not registered, 0-255 characters

local function checkAuthCode(code, first_name, last_name)

  tdcli_function ({

    ID = "CheckAuthCode",

    code_ = code,

    first_name_ = first_name,

    last_name_ = last_name

  }, dl_cb, nil)

end


M.checkAuthCode = checkAuthCode


-- Checks password for correctness.

-- Works only when authGetState returns authStateWaitPassword.

-- Returns authStateOk on success @password Password to check

local function checkAuthPassword(password)

  tdcli_function ({

    ID = "CheckAuthPassword",

    password_ = password

  }, dl_cb, nil)

end


M.checkAuthPassword = checkAuthPassword


-- Requests to send password recovery code to email.

-- Works only when authGetState returns authStateWaitPassword.

-- Returns authStateWaitPassword on success

local function requestAuthPasswordRecovery()

  tdcli_function ({

    ID = "RequestAuthPasswordRecovery",

  }, dl_cb, nil)

end


M.requestAuthPasswordRecovery = requestAuthPasswordRecovery


-- Recovers password with recovery code sent to email.

-- Works only when authGetState returns authStateWaitPassword.

-- Returns authStateOk on success @recovery_code Recovery code to check

local function recoverAuthPassword(recovery_code)

  tdcli_function ({

    ID = "RecoverAuthPassword",

    recovery_code_ = recovery_code

  }, dl_cb, nil)

end


M.recoverAuthPassword = recoverAuthPassword


-- Logs out user.

-- If force == false, begins to perform soft log out, returns authStateLoggingOut after completion.

-- If force == true then succeeds almost immediately without cleaning anything at the server, but returns error with code 401 and description "Unauthorized"

-- @force If true, just delete all local data. Session will remain in list of active sessions

local function resetAuth(force)

  tdcli_function ({

    ID = "ResetAuth",

    force_ = force or nil

  }, dl_cb, nil)

end


M.resetAuth = resetAuth


-- Check bot's authentication token to log in as a bot.

-- Works only when authGetState returns authStateWaitPhoneNumber.

-- Can be used instead of setAuthPhoneNumber and checkAuthCode to log in.

-- Returns authStateOk on success @token Bot token

local function checkAuthBotToken(token)

  tdcli_function ({

    ID = "CheckAuthBotToken",

    token_ = token

  }, dl_cb, nil)

end


M.checkAuthBotToken = checkAuthBotToken


-- Returns current state of two-step verification

local function getPasswordState()

  tdcli_function ({

    ID = "GetPasswordState",

  }, dl_cb, nil)

end


M.getPasswordState = getPasswordState


-- Changes user password.

-- If new recovery email is specified, then error EMAIL_UNCONFIRMED is returned and password change will not be applied until email will be confirmed.

-- Application should call getPasswordState from time to time to check if email is already confirmed

-- @old_password Old user password

-- @new_password New user password, may be empty to remove the password

-- @new_hint New password hint, can be empty

-- @set_recovery_email Pass True, if recovery email should be changed

-- @new_recovery_email New recovery email, may be empty

local function setPassword(old_password, new_password, new_hint, set_recovery_email, new_recovery_email)

  tdcli_function ({

    ID = "SetPassword",

    old_password_ = old_password,

    new_password_ = new_password,

    new_hint_ = new_hint,

    set_recovery_email_ = set_recovery_email,

    new_recovery_email_ = new_recovery_email

  }, dl_cb, nil)

end


M.setPassword = setPassword


-- Returns set up recovery email 

-- @password Current user password

local function getRecoveryEmail(password)

  tdcli_function ({

    ID = "GetRecoveryEmail",

    password_ = password

  }, dl_cb, nil)

end


M.getRecoveryEmail = getRecoveryEmail


-- Changes user recovery email

-- @password Current user password

-- @new_recovery_email New recovery email

local function setRecoveryEmail(password, new_recovery_email)

  tdcli_function ({

    ID = "SetRecoveryEmail",

    password_ = password,

    new_recovery_email_ = new_recovery_email

  }, dl_cb, nil)

end


M.setRecoveryEmail = setRecoveryEmail


-- Requests to send password recovery code to email

local function requestPasswordRecovery()

  tdcli_function ({

    ID = "RequestPasswordRecovery",

  }, dl_cb, nil)

end


M.requestPasswordRecovery = requestPasswordRecovery


-- Recovers password with recovery code sent to email

-- @recovery_code Recovery code to check

local function recoverPassword(recovery_code)

  tdcli_function ({

    ID = "RecoverPassword",

    recovery_code_ = tostring(recovery_code)

  }, dl_cb, nil)

end


M.recoverPassword = recoverPassword


-- Returns current logged in user

local function getMe()

  tdcli_function ({

    ID = "GetMe",

  }, dl_cb, nil)

end


M.getMe = getMe


-- Returns information about a user by its identifier, offline request if current user is not a bot

-- @user_id User identifier

local function getUser(user_id)

  tdcli_function ({

    ID = "GetUser",

    user_id_ = user_id

  }, dl_cb, nil)

end


M.getUser = getUser


-- Returns full information about a user by its identifier

-- @user_id User identifier

local function getUserFull(user_id)

  tdcli_function ({

    ID = "GetUserFull",

    user_id_ = user_id

  }, dl_cb, nil)

end


M.getUserFull = getUserFull


-- Returns information about a group by its identifier, offline request if current user is not a bot

-- @group_id Group identifier

local function getGroup(group_id)

  tdcli_function ({

    ID = "GetGroup",

    group_id_ = getChatId(group_id).ID

  }, dl_cb, nil)

end


M.getGroup = getGroup


-- Returns full information about a group by its identifier

-- @group_id Group identifier

local function getGroupFull(group_id)

  tdcli_function ({

    ID = "GetGroupFull",

    group_id_ = getChatId(group_id).ID

  }, dl_cb, nil)

end


M.getGroupFull = getGroupFull


-- Returns information about a channel by its identifier, offline request if current user is not a bot

-- @channel_id Channel identifier

local function getChannel(channel_id)

  tdcli_function ({

    ID = "GetChannel",

    channel_id_ = getChatId(channel_id).ID

  }, dl_cb, nil)

end


M.getChannel = getChannel


-- Returns full information about a channel by its identifier, cached for at most 1 minute

-- @channel_id Channel identifier

local function getChannelFull(channel_id)

  tdcli_function ({

    ID = "GetChannelFull",

    channel_id_ = getChatId(channel_id).ID

  }, dl_cb, nil)

end


M.getChannelFull = getChannelFull


-- Returns information about a chat by its identifier, offline request if current user is not a bot

-- @chat_id Chat identifier

local function getChat(chat_id)

  tdcli_function ({

    ID = "GetChat",

    chat_id_ = chat_id

  }, dl_cb, nil)

end


M.getChat = getChat


-- Returns information about a message

-- @chat_id Identifier of the chat, message belongs to

-- @message_id Identifier of the message to get

local function getMessage(chat_id, message_id)

  tdcli_function ({

    ID = "GetMessage",

    chat_id_ = chat_id,

    message_id_ = message_id

  }, dl_cb, nil)

end


M.getMessage = getMessage


-- Returns information about messages.

-- If message is not found, returns null on the corresponding position of the result

-- @chat_id Identifier of the chat, messages belongs to

-- @message_ids Identifiers of the messages to get

local function getMessages(chat_id, message_ids)

  tdcli_function ({

    ID = "GetMessages",

    chat_id_ = chat_id,

    message_ids_ = message_ids -- vector

  }, dl_cb, nil)

end


M.getMessages = getMessages


-- Returns information about a file, offline request

-- @file_id Identifier of the file to get

local function getFile(file_id)

  tdcli_function ({

    ID = "GetFile",

    file_id_ = file_id

  }, dl_cb, nil)

end


M.getFile = getFile


-- Returns information about a file by its persistent id, offline request

-- @persistent_file_id Persistent identifier of the file to get

local function getFilePersistent(persistent_file_id)

  tdcli_function ({

    ID = "GetFilePersistent",

    persistent_file_id_ = persistent_file_id

  }, dl_cb, nil)

end


M.getFilePersistent = getFilePersistent


-- BAD RESULT

-- Returns list of chats in the right order, chats are sorted by (order, chat_id) in decreasing order. 

-- For example, to get list of chats from the beginning, the offset_order should be equal 2^63 - 1 

-- @offset_order Chat order to return chats from 

-- @offset_chat_id Chat identifier to return chats from 

-- @limit Maximum number of chats to be returned

local function getChats(offset_order, offset_chat_id, limit)

  if not limit or limit > 20 then

    limit = 20

  end

  

  tdcli_function ({

    ID = "GetChats",

    offset_order_ = offset_order or 9223372036854775807,

    offset_chat_id_ = offset_chat_id or 0,

    limit_ = limit

  }, dl_cb, nil)

end


M.getChats = getChats


-- Searches public chat by its username.

