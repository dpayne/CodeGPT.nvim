local curl = require("plenary.curl")
local Providers = require("codegpt.providers")
local OpenAIApi = {}

local function remove_by_key(t, k)
	for i, v in ipairs(t) do
		if v == k then
			t[i] = nil
		end
	end
end

local function curl_callback(response, cb, request_id)
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

	remove_by_key(require("CodeGPT").loading_state, request_id)

	vim.g["codegpt_hooks"]["request_finished"]()
end

local function random_unique_id()
	local id = math.random(0, 9999999999)
	while require("CodeGPT").loading_state[id] do
		id = math.random(0, 9999999999)
	end
	return id
end

function OpenAIApi.make_call(payload, cb)
	local payload_str = vim.fn.json_encode(payload)
	local url = vim.g["codegpt_chat_completions_url"]
	local headers = Providers.get_provider().make_headers()

	local request_id = random_unique_id()
	table.insert(require("CodeGPT").loading_state, request_id)

	vim.g["codegpt_hooks"]["request_started"]()

	curl.post(url, {
		body = payload_str,
		headers = headers,
		callback = function(response)
			curl_callback(response, cb, request_id)
		end,
	})
end

return OpenAIApi
