local OpenAiApi = require("codegpt.openai_api")
local CommandsList = require("codegpt.commands_list")
local Render = require("codegpt.template_render")

local Commands = {}

local function generate_messages(command, cmd_opts, command_args, text_selection)
  local system_message = Render.render(command, cmd_opts.system_message_template, command_args, text_selection)
  local user_message = Render.render(command, cmd_opts.user_message_template, command_args, text_selection)

  local messages = {}
  if system_message ~= nil and system_message ~= "" then
    table.insert(messages, {role = "system", content = system_message})
  end

  if user_message ~= nil and user_message ~= "" then
    table.insert(messages, {role = "user", content = user_message})
  end

  return messages
end

local function get_max_tokens(max_tokens, messages)
  local total_length = 0
  for _, message in ipairs(messages) do
    total_length = total_length + string.len(message.content)
    total_length = total_length + string.len(message.role)
  end

  if total_length >= max_tokens then
      error("Total length of messages exceeds max_tokens: " .. total_length .. " > " .. max_tokens)
  end

  return max_tokens - total_length
end

function Commands.run_cmd(command, command_args, text_selection)
  local cmd_opts = CommandsList.get_cmd_opts(command)
  if cmd_opts == nil then
      error("Command not found: " .. command)
  end

  local messages = generate_messages(command, cmd_opts, command_args, text_selection)

  local request = {
    max_tokens = get_max_tokens(cmd_opts.max_tokens, messages),
    temperature = cmd_opts.temperature,
    n = cmd_opts.number_of_choices,
    model = cmd_opts.model,
    messages = messages,
  }

  OpenAiApi.make_call(request, cmd_opts.callback)
end

return Commands
