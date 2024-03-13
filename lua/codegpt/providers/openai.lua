local Render = require("codegpt.template_render")
local Utils = require("codegpt.utils")

OpenAIProvider = {}

local function generate_messages(command, cmd_opts, command_args, text_selection)
    local system_message = Render.render(command, cmd_opts.system_message_template, command_args, text_selection,
        cmd_opts)
    local user_message = Render.render(command, cmd_opts.user_message_template, command_args, text_selection, cmd_opts)

    local messages = {}
    if system_message ~= nil and system_message ~= "" then
        table.insert(messages, { role = "system", content = system_message })
    end

    if user_message ~= nil and user_message ~= "" then
        table.insert(messages, { role = "user", content = user_message })
    end

    return messages
end

local function get_max_tokens(max_tokens, messages)
    local ok, total_length = Utils.get_accurate_tokens(vim.fn.json_encode(messages))

    if not ok then
        for _, message in ipairs(messages) do
            total_length = total_length + string.len(message.content)
            total_length = total_length + string.len(message.role)
        end
    end

    if total_length >= max_tokens then
        error("Total length of messages exceeds max_tokens: " .. total_length .. " > " .. max_tokens)
    end

    return max_tokens - total_length
end

function OpenAIProvider.make_request(command, cmd_opts, command_args, text_selection)
    local messages = generate_messages(command, cmd_opts, command_args, text_selection)
    local max_tokens = get_max_tokens(cmd_opts.max_tokens, messages)

    local request = {
        temperature = cmd_opts.temperature,
        n = cmd_opts.number_of_choices,
        model = cmd_opts.model,
        messages = messages,
        max_tokens = max_tokens,
    }

    request = vim.tbl_extend("force", request, cmd_opts.extra_params)
    return request
end

function OpenAIProvider.make_headers()
    local token = vim.g["codegpt_openai_api_key"]
    if not token then
        error(
            "OpenAIApi Key not found, set in vim with 'codegpt_openai_api_key' or as the env variable 'OPENAI_API_KEY'"
        )
    end

    return { Content_Type = "application/json", Authorization = "Bearer " .. token }
end

function OpenAIProvider.handle_response(json, cb)
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
                if vim.g["codegpt_clear_visual_selection"] then
                    vim.api.nvim_buf_set_mark(bufnr, "<", 0, 0, {})
                    vim.api.nvim_buf_set_mark(bufnr, ">", 0, 0, {})
                end
                cb(Utils.parse_lines(response_text))
            end
        else
            print("Error: No message")
        end
    end
end

return OpenAIProvider
