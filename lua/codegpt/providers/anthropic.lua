local curl = require("plenary.curl")
local Render = require("codegpt.template_render")
local Utils = require("codegpt.utils")
local Api = require("codegpt.api")

AnthropicProvider = {}

local function generate_messages(command, cmd_opts, command_args, text_selection)
    local user_message = Render.render(command, cmd_opts.user_message_template, command_args, text_selection, cmd_opts)

    local messages = {}
    if user_message ~= nil and user_message ~= "" then
        table.insert(messages, { role = "user", content = user_message })
    end

    return messages
end

function AnthropicProvider.make_request(command, cmd_opts, command_args, text_selection)
    local system_message = Render.render(command, cmd_opts.system_message_template, command_args, text_selection,
        cmd_opts)
    local messages = generate_messages(command, cmd_opts, command_args, text_selection)

    -- context window is 100k-200k tokens
    -- but the output is fixed at 4096 tokens
    local max_tokens = 4096

    local request = {
        temperature = cmd_opts.temperature or 1.0,
        max_tokens = max_tokens,
        model = cmd_opts.model,
        system = system_message,
        messages = messages,
    }

    return request
end

function AnthropicProvider.make_headers()
    local api_key = vim.g["codegpt_anthropic_api_key"] or os.getenv("ANTHROPIC_API_KEY")

    if not api_key then
        error(
            "Anthropic API Key not found, set in vim with 'codegpt_anthropic_api_key' or as the env variable 'ANTHROPIC_API_KEY'"
        )
    end

    return {
        ["Content-Type"] = "application/json",
        ["X-API-Key"] = api_key,
        ["anthropic-version"] = "2023-06-01",
    }
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
        AnthropicProvider.handle_response(json, cb)
    end)(body)

    Api.run_finished_hook()
end


function AnthropicProvider.handle_response(json, cb)
    if json == nil then
        print("Response empty")
    elseif json.error then
        print("Error: " .. json.error.message)
    elseif json.stop_reason ~= "end_turn" then
        print("Response is incomplete. Payload: " .. vim.fn.json_encode(json))
    else
        if json.content[1] ~= nil then
            local response_text = json.content[1].text

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
                print("Error: No completion")
            end
        else
            print("Error: No completion")
        end
    end
end

function AnthropicProvider.make_call(payload, cb)
    local payload_str = vim.fn.json_encode(payload)
    local url = "https://api.anthropic.com/v1/messages"
    local headers = AnthropicProvider.make_headers()
    Api.run_started_hook()
    curl.post(url, {
        body = payload_str,
        headers = headers,
        callback = function(response)
            curl_callback(response, cb)
        end,
        on_error = function(err)
            print('Curl error:', err.message)
            Api.run_finished_hook()
        end,
    })
end

return AnthropicProvider
