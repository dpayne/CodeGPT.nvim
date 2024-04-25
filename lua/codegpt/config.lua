if os.getenv("OPENAI_API_KEY") ~= nil then
    vim.g["codegpt_openai_api_key"] = os.getenv("OPENAI_API_KEY")
end
vim.g["codegpt_chat_completions_url"] = "https://api.openai.com/v1/chat/completions"

-- Read old config if it exists
if vim.g["codegpt_openai_api_provider"] and #vim.g["codegpt_openai_api_provider"] > 0 then
    vim.g["codegpt_api_provider"] = vim.g["codegpt_openai_api_provider"]
end

-- alternative provider
vim.g["codegpt_api_provider"] = vim.g["codegpt_api_provider"] or "openai"

-- clears visual selection after completion
vim.g["codegpt_clear_visual_selection"] = true

vim.g["codegpt_hooks"] = {
    request_started = nil,
    request_finished = nil,
}

-- Border style to use for the popup
vim.g["codegpt_popup_border"] = { style = "rounded" }

-- Wraps the text on the popup window, deprecated in favor of codegpt_popup_window_options
vim.g["codegpt_wrap_popup_text"] = true

vim.g["codegpt_popup_window_options"] = {}

-- set the filetype of a text popup is markdown
vim.g["codegpt_text_popup_filetype"] = "markdown"

-- Set the type of ui to use for the popup, options are "popup", "vertical" or "horizontal"
vim.g["codegpt_popup_type"] = "popup"

-- Set the height of the horizontal popup
vim.g["codegpt_horizontal_popup_size"] = "20%"

-- Set the width of the vertical popup
vim.g["codegpt_vertical_popup_size"] = "20%"

vim.g["codegpt_commands_defaults"] = {
    ["completion"] = {
        user_message_template =
        "I have the following {{language}} code snippet: ```{{filetype}}\n{{text_selection}}```\nComplete the rest. Use best practices and write really good documentation. {{language_instructions}} Only return the code snippet and nothing else.",
        language_instructions = {
            cpp = "Use modern C++ features.",
            java = "Use modern Java syntax. Use var when applicable.",
        },
    },
    ["generate"] = {
        user_message_template =
        "Write code in {{language}} using best practices and write really good documentation. {{language_instructions}} Only return the code snippet and nothing else. {{command_args}}",
        language_instructions = {
            cpp = "Use modern C++ features.",
            java = "Use modern Java syntax. Use var when applicable.",
        },
        allow_empty_text_selection = true,
    },
    ["code_edit"] = {
        user_message_template =
        "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\n{{command_args}}. {{language_instructions}} Only return the code snippet and nothing else.",
        language_instructions = {
            cpp = "Use modern C++ syntax.",
        },
    },
    ["explain"] = {
        user_message_template =
        "Explain the following {{language}} code: ```{{filetype}}\n{{text_selection}}``` Explain as if you were explaining to another developer.",
        callback_type = "text_popup",
    },
    ["question"] = {
        user_message_template =
        "I have a question about the following {{language}} code: ```{{filetype}}\n{{text_selection}}``` {{command_args}}",
        callback_type = "text_popup",
    },
    ["debug"] = {
        user_message_template =
        "Analyze the following {{language}} code for bugs: ```{{filetype}}\n{{text_selection}}```",
        callback_type = "text_popup",
    },
    ["doc"] = {
        user_message_template =
        "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nWrite really good documentation using best practices for the given language. Attention paid to documenting parameters, return types, any exceptions or errors. {{language_instructions}} Only return the code snippet and nothing else.",
        language_instructions = {
            cpp = "Use doxygen style comments for functions.",
            java = "Use JavaDoc style comments for functions.",
        },
    },
    ["opt"] = {
        user_message_template =
        "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nOptimize this code. {{language_instructions}} Only return the code snippet and nothing else.",
        language_instructions = {
            cpp = "Use modern C++.",
        },
    },
    ["tests"] = {
        user_message_template =
        "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nWrite really good unit tests using best practices for the given language. {{language_instructions}} Only return the unit tests. Only return the code snippet and nothing else. ",
        callback_type = "code_popup",
        language_instructions = {
            cpp = "Use modern C++ syntax. Generate unit tests using the gtest framework.",
            java = "Generate unit tests using the junit framework.",
        },
    },
    ["chat"] = {
        system_message_template = "You are a general assistant to a software developer.",
        user_message_template = "{{command_args}}",
        callback_type = "text_popup",
    },
}

-- Popup commands
vim.g["codegpt_ui_commands"] = {
    quit = "q",
    use_as_output = "<c-o>",
    use_as_input = "<c-i>",
}
vim.g["codegpt_ui_custom_commands"] = {}
