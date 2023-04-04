local Render = require("codegpt.template_render")
local Utils = require("codegpt.utils")

AzureProvider = {}

local function generate_messages_legacy(command, cmd_opts, command_args, text_selection, system_message, user_message)
	local prompt = ""
	if system_message ~= nil and system_message ~= "" then
		prompt = "<|im_start|>" .. prompt .. "system\n" .. system_message .. "\n<|im_end|>\n"
	end

	if user_message ~= nil and user_message ~= "" then
		prompt = prompt .. "<|im_start|>user\n" .. user_message .. "\n<|im_end|>\n<|im_start|>assistant\n"
	end

	return prompt
end

local function is_legacy()
	-- Azure OpenAI supports multiple APIs.
	-- We should check if `codegpt_chat_completions_url` is match
	-- `/deployments/{deployment-id}/chat/completions`
	-- If not, should use the legacy parameters
	local completions_url = vim.g["codegpt_chat_completions_url"]

	return vim.fn.match(completions_url, "/chat/completions") == -1
end

local function generate_messages(command, cmd_opts, command_args, text_selection)
	local system_message = Render.render(command, cmd_opts.system_message_template, command_args, text_selection)
	local user_message = Render.render(command, cmd_opts.user_message_template, command_args, text_selection)
	if is_legacy() then
		return generate_messages_legacy(command, cmd_opts, command_args, text_selection, system_message, user_message)
	end

	local prompt = {}
	if system_message ~= nil and system_message ~= "" then
		table.insert(prompt, { role = "system", content = system_message })
	end

	if user_message ~= nil and user_message ~= "" then
		table.insert(prompt, { role = "user", content = user_message })
	end

	return prompt
end

local function get_max_tokens_legacy(max_tokens, messages)
	local total_length = string.len(messages)

	if total_length >= max_tokens then
		error("Total length of messages exceeds max_tokens: " .. total_length .. " > " .. max_tokens)
	end

	return max_tokens - total_length
end

local function get_max_tokens(max_tokens, messages)
	if is_legacy() then
		return get_max_tokens_legacy(max_tokens, messages)
	end

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

function AzureProvider.make_request(command, cmd_opts, command_args, text_selection)
	local messages = generate_messages(command, cmd_opts, command_args, text_selection)
	local max_tokens = get_max_tokens(cmd_opts.max_tokens, messages)

	local request = {
		temperature = cmd_opts.temperature,
		n = cmd_opts.number_of_choices,
		model = cmd_opts.model,
		max_tokens = max_tokens,
	}
	if is_legacy() then
		request["stop"] = "<|im_end|>"
		request["prompt"] = messages
	else
		request["messages"] = messages
	end

	return request
end

function AzureProvider.make_headers()
	local token = vim.g["codegpt_openai_api_key"]
	if not token then
		error(
			"OpenAIApi Key not found, set in vim with 'codegpt_openai_api_key' or as the env variable 'OPENAI_API_KEY'"
		)
	end

	return { Content_Type = "application/json", ["api-key"] = token }
end

local function handle_response_legacy(json, cb)
	if not json.choices or 0 == #json.choices or not json.choices[1].text then
		print("Error: " .. vim.fn.json_encode(json))
		return
	end

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

function AzureProvider.handle_response(json, cb)
	if json == nil then
		print("Response empty")
	elseif json.error then
		print("Error: " .. json.error.message)
	end
	if is_legacy() then
		return handle_response_legacy(json, cb)
	end

	if not json.choices or 0 == #json.choices or not json.choices[1].message then
		print("Error: " .. vim.fn.json_encode(json))
		return
	end

	local response_text = json.choices[1].message.content

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

return AzureProvider
