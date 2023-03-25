local curl = require("plenary.curl")
local Providers = require("codegpt.providers")
local OpenAIApi = {}

CODEGPT_CALLBACK_COUNTER = 0

local status_index = 0
local progress_bar_dots = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

function OpenAIApi.get_status(...)
	if CODEGPT_CALLBACK_COUNTER > 0 then
		status_index = status_index + 1
		if status_index > #progress_bar_dots then
			status_index = 1
		end
		return progress_bar_dots[status_index]
	else
		return ""
	end
end

local function run_started_hook()
	if vim.g["codegpt_hooks"]["request_started"] ~= nil then
		vim.g["codegpt_hooks"]["request_started"]()
	end

	CODEGPT_CALLBACK_COUNTER = CODEGPT_CALLBACK_COUNTER + 1
end

local function run_finished_hook()
	CODEGPT_CALLBACK_COUNTER = CODEGPT_CALLBACK_COUNTER - 1
	if CODEGPT_CALLBACK_COUNTER <= 0 then
		if vim.g["codegpt_hooks"]["request_finished"] ~= nil then
			vim.g["codegpt_hooks"]["request_finished"]()
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
		Providers.get_provider().handle_response(json, cb)
	end)(body)

	run_finished_hook()
end

function OpenAIApi.make_call(payload, cb, selection)
	local payload_str = vim.fn.json_encode(payload)
	local url = vim.g["codegpt_chat_completions_url"]
	local headers = Providers.get_provider().make_headers()

	run_started_hook()

	curl.post(url, {
		body = payload_str,
		headers = headers,
		callback = function(response)
			curl_callback(response, cb, selection)
		end,
	})
end

return OpenAIApi
