local curl = require("plenary.curl")
local Providers = require("codegpt.providers")
local OpenAIApi = {}

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
    Providers.get_provider().handle_response(json, cb)
  end)(body)
end

function OpenAIApi.make_call(payload, cb)
  local payload_str = vim.fn.json_encode(payload)
  local url = vim.g["codegpt_chat_completions_url"]
  local headers = Providers.get_provider().make_headers()

  curl.post(url, {
    body = payload_str,
    headers = headers,
    callback = function(response)
      curl_callback(response, cb)
    end,
  })
end

return OpenAIApi
