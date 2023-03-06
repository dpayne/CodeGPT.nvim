local curl = require("plenary.curl")
local OpenAIApi = {}

local function get_code_block(lines2)
    local code_block = {}
    local in_code_block = false
    for _, line in ipairs(lines2) do
        if line:match("^```") then
            in_code_block = not in_code_block
        elseif in_code_block then
            table.insert(code_block, line)
        end
    end
    return code_block
end

local function contains_code_block(lines2)
    for _, line in ipairs(lines2) do
        if line:match("^```") then
            return true
        end
    end
    return false
end

local function parse_lines(response_text)
  if vim.g["codegpt_write_response_to_err_log"] then
    vim.api.nvim_err_write("ChatGPT response: \n" .. response_text .. "\n")
  end

  local lines = vim.fn.split(response_text, "\n")
  if contains_code_block(lines) then
    return get_code_block(lines)
  end

  return lines
end

local function handle_response(json, cb)
  if json == nil then
    print("Response empty")
  elseif json.error then
    print("Error: " .. json.error.message)
  elseif not json.choices or 0 == #json.choices or not json.choices[1].message then
    print("Error: " .. vim.fn.json_encode(json))
  else
    local response_text = json.choices[1].message.content
    if response_text ~= nil then
      if type(response_text) ~= "string" or response_text == "" then
        print("Error: No response text " .. type(response_text))
      else
        local bufnr = vim.api.nvim_get_current_buf()
        cb(parse_lines(response_text))
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

local function curl_callback(response, cb)
  local status = response.status
  local body = response.body
  if status ~= 200 then
    body = body:gsub("%s+", " ")
    print("Error: " .. status .. " " .. body)
    return
  end

  if body == nil or body == "" then
    print("Error: No body")
    return
  end
  vim.schedule_wrap(function(msg)
    local json = vim.fn.json_decode(msg)
    handle_response(json, cb)
  end)(body)
end

function OpenAIApi.make_call(payload, cb)
  local token = vim.g["codegpt_openai_api_key"]
  if not token then
    error("OpenAIApi Key not found, set in vim with 'codegpt_openai_api_key' or as the env variable 'OPENAI_API_KEY'")
  end

  local payload_str = vim.fn.json_encode(payload)
  local url = vim.g["codegpt_chat_completions_url"]
  curl.post(url, {
    body = payload_str,
    headers = {
      Content_Type = "application/json",
      Authorization = "Bearer " .. token,
    },
    callback = function(response)
      curl_callback(response, cb)
    end,
  })
end

return OpenAIApi
