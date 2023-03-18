local Render = require("codegpt.template_render")
local Utils = require("codegpt.utils")

AzureProvider = {}

local function generate_messages(command, cmd_opts, command_args, text_selection)
  local system_message = Render.render(command, cmd_opts.system_message_template, command_args, text_selection)
  local user_message = Render.render(command, cmd_opts.user_message_template, command_args, text_selection)

  local prompt = ""
  if system_message ~= nil and system_message ~= "" then
      prompt = "<|im_start|>" .. prompt .. "system\n" .. system_message .. "\n<|im_end|>\n"
  end
  
  if user_message ~= nil and user_message ~= "" then
      prompt = prompt .. "<|im_start|>user\n" .. user_message .. "\n<|im_end|>\n<|im_start|>assistant\n"
  end
  
  return prompt
end

local function get_max_tokens(max_tokens, messages)
  local total_length = string.len(messages)

  if total_length >= max_tokens then
      error("Total length of messages exceeds max_tokens: " .. total_length .. " > " .. max_tokens)
  end

  return max_tokens - total_length
end



function AzureProvider.make_request(command, cmd_opts, command_args, text_selection)
  local messages = generate_messages(command, cmd_opts, command_args, text_selection)
  local max_tokens = get_max_tokens(cmd_opts.max_tokens, messages)

  local request = {
    temperature = cmd_opts.temperature,
    n = cmd_opts.number_of_choices,
    model = cmd_opts.model,
    prompt = messages,
    max_tokens = max_tokens,
    stop = "<|im_end|>",
  }

  return request
end

function AzureProvider.make_headers()
  local token = vim.g["codegpt_openai_api_key"]
  if not token then
    error("OpenAIApi Key not found, set in vim with 'codegpt_openai_api_key' or as the env variable 'OPENAI_API_KEY'")
  end

  return { Content_Type = "application/json", ["api-key"] = token }
end

function AzureProvider.handle_response(json, cb)
  if json == nil then
    print("Response empty")
  elseif json.error then
    print("Error: " .. json.error.message)
  elseif not json.choices or 0 == #json.choices or not json.choices[1].text then
    print("Error: " .. vim.fn.json_encode(json))
  else
    local response_text = json.choices[1].text

    if response_text ~= nil then
      if type(response_text) ~= "string" or response_text == "" then
        print("Error: No response text " .. type(response_text))
      else
        local bufnr = vim.api.nvim_get_current_buf()
        cb(Utils.parse_lines(response_text))
        if vim.g["codegpt_clear_visual_selection"] then
            vim.api.nvim_buf_set_mark(bufnr, "<", 0, 0, {})
            vim.api.nvim_buf_set_mark(bufnr, ">", 0, 0, {})
        end
      end
    else
      print("Error: No message")
    end
  end
end

return AzureProvider
