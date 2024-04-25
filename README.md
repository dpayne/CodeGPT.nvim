# CodeGPT.nvim

CodeGPT is a plugin for neovim that provides commands to interact with ChatGPT. The focus is around code related usages. So code completion, refactorings, generating docs, etc.

## Installation

* Set environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys).
* The plugins 'plenary' and 'nui' are also required.
* OpenAI's tokenizer [tiktoken](https://github.com/openai/tiktoken) is recommended for accurate token count estimate.

Installing with Lazy.

```lua
{
    "dpayne/CodeGPT.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    config = function()
        require("codegpt.config")
    end
}
```

Installing with packer.

```lua
use({
   "dpayne/CodeGPT.nvim",
   requires = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
   },
   config = function()
      require("codegpt.config")
   end
})
```

Installing with plugged.

```vim
Plug("nvim-lua/plenary.nvim")
Plug("MunifTanjim/nui.nvim")
Plug("dpayne/CodeGPT.nvim")
```

Installing OpenAI's tokenizer
```sh
pip install tiktoken
```

## Commands

The top-level command is `:Chat`. The behavior is different depending on whether text is selected and/or arguments are passed.

### Completion
* `:Chat` with text selection will trigger the `completion` command, ChatGPT will try to complete the selected code snippet.
![completion](examples/completion.gif?raw=true)

### Code Edit
* `:Chat some instructions` with text selection and command args will invoke the `code_edit` command. This will treat the command args as instructions on what to do with the code snippet. In the below example, `:Chat refactor to use iteration` will apply the instruction `refactor to use iteration` to the selected code.
![code_edit](examples/code_edit.gif?raw=true)

### Code Edit
* `:Chat <command>` if there is only one argument and that argument matches a command, it will invoke that command with the given text selection. In the below example `:Chat tests` will attempt to write units for the selected code.
![tests](examples/tests.gif?raw=true)

### Chat
* `:Chat hello world` without any text selection will trigger the `chat` command. This will send the arguments `hello world` to ChatGPT and show the results in a popup.
![chat](examples/chat.gif?raw=true)


A full list of predefined commands are below

| command      | input | Description |
|--------------|---- |------------------------------------|
| completion |  text selection | Will ask ChatGPT to complete the selected code. |
| code_edit  |  text selection and command args | Will ask ChatGPT to apply the given instructions (the command args) to the selected code. |
| explain  |  text selection | Will ask ChatGPT to explain the selected code. |
| question  |  text selection | Will pass the commands args to ChatGPT and return the answer in a text popup. |
| debug  |  text selection | Will pass the code selectiont to ChatGPT analyze it for bugs, the results will be in a text popup. |
| doc  |  text selection | Will ask ChatGPT to document the selected code. |
| opt  |  text selection | Will ask ChatGPT to optimize the selected code. |
| tests  |  text selection | Will ask ChatGPT to write unit tests for the selected code. |
| chat  |  command args | Will pass the given command args to ChatGPT and return the response in a popup. |


## Overriding Command Configurations

The configuration option `vim.g["codegpt_commands_defaults"] = {}` can be used to override command configurations. This is a lua table with a list of commands and the options you want to override.

```lua
vim.g["codegpt_commands_defaults"] = {
  ["completion"] = {
      user_message_template = "This is a template of the message passed to chat gpt. Hello, the code snippet is {{text_selection}}."
}
```
The above, overrides the message template for the `completion` command.

A full list of overrides

| name                    | default         | description                                                                                                                                                       |
|-------------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| model                   | "gpt-3.5-turbo" | The model to use.                                                                                                                                                 |
| max_tokens              | 4096            | The maximum number of tokens to use including the prompt tokens.                                                                                                  |
| temperature             | 0.6             | 0 -> 1, what sampling temperature to use.                                                                                                                         |
| system_message_template | ""              | Helps set the behavior of the assistant.                                                                                                                          |
| user_message_template   | ""              | Instructs the assistant.                                                                                                                                          |
| callback_type           | "replace_lines" | Controls what the plugin does with the response                                                                                                                   |
| language_instructions   | {}              | A table of filetype => instructions. The current buffer's filetype is used in this lookup. This is useful trigger different instructions for different languages. |
| extra_params            | {}              | A table of custom parameters to be sent to the API.                                                                                                               |



### Overriding the global defaults

The overrides can be set globally using `vim.g["codegpt_global_commands_defaults"]`. This can be useful to setup a custom configuration for APIs that emulate OpenAI such as LocalAI.

```lua
    vim.g["codegpt_global_commands_defaults"] = { 
        model = "mixtral",
        max_tokens = 4096,
        temperature = 0.4,
        -- extra_parms = { -- optional list of extra parameters to send to the API
        --     presence_penalty = 1,
        --     frequency_penalty= 1
        -- }
    }
```



#### Templates

The `system_message_template` and the `user_message_template` can contain template macros. For example:

| macro | description |
|------|-------------|
| `{{filetype}}` | The `filetype` of the current buffer. |
| `{{text_selection}}` | The selected text in the current buffer. |
| `{{language}}` | The name of the programming language in the current buffer. |
| `{{command_args}}` | Everything passed to the command as an argument, joined with spaces. See below. |
| `{{language_instructions}}` | The found value in the `language_instructions` map. See below. |


#### Language Instructions

Some commands have templates that use the `{{language_instructions}}` macro to allow for additional instructions for specific [filetypes](https://neovim.io/doc/user/filetype.html).

```lua
vim.g["codegpt_commands_defaults"] = {
  ["completion"] = {
      language_instructions = {
          cpp = "Use trailing return type.",
      },
  }
}
```

The above adds a specific `Use trailing return type.` to the command `completion` for the filetype `cpp`.


#### Command Args

Commands are normally a single value, for example `:Chat completion`. Normally, a command such as `:Chat completion value` will be interpreted as a `code_edit` command, with the arguments `"completion value"`, and not `completion` with `"value"`. You can make commands accept additional arguments by using the `{{command_args}}` macro anywhere in either `user_message_template` or `system_message_template`. For example:

```lua
vim.g["codegpt_commands"] = {
  ["testwith"] = {
      user_message_template =
        "Write tests for the following code: ```{{filetype}}\n{{text_selection}}```\n{{command_args}} " ..
        "Only return the code snippet and nothing else."
  }
}
```

After defining this command, any `:Chat` command that has `testwith` as its first argument will be handled. For example, `:Chat testwith some additional instructions` will be interpreted as `testwith` with `"some additional instructions"`.


## Custom Commands


Custom commands can be added to the `vim.g["codegpt_commands"]` configuration option to extend the available commands.

```lua
vim.g["codegpt_commands"] = {
  ["modernize"] = {
      user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nModernize the above code. Use current best practices. Only return the code snippet and comments. {{language_instructions}}",
      language_instructions = {
          cpp = "Refactor the code to use trailing return type, and the auto keyword where applicable.",
      },
  }
}
```
The above configuration adds the command `:Chat modernize` that attempts modernize the selected code snippet.


##  Command Defaults

The default command configuration is:

```lua
{
    model = "gpt-3.5-turbo",
    max_tokens = 4096,
    temperature = 0.6,
    number_of_choices = 1,
    system_message_template = "",
    user_message_template = "",
    callback_type = "replace_lines",
}
```

## More Configuration Options

### Custom status hooks

You can add custom hooks to update your status line or other ui elements, for example, this code updates the status line colour to yellow whilst the request is in progress.

```lua
vim.g["codegpt_hooks"] = {
	request_started = function()
		vim.cmd("hi StatusLine ctermbg=NONE ctermfg=yellow")
	end,
  request_finished = vim.schedule_wrap(function()
		vim.cmd("hi StatusLine ctermbg=NONE ctermfg=NONE")
	end)
}
```

### Lualine Status Component

There is a convenience function `get_status` so that you can add a status component to lualine.

```lua
local CodeGPTModule = require("codegpt")

require('lualine').setup({
    sections = {
        -- ...
        lualine_x = { CodeGPTModule.get_status, "encoding", "fileformat" },
        -- ...
    }
})
```

### Popup options

#### Popup commands

The default filetype of the text popup window is markdown. You can change this by setting the `codegpt_popup_options` variable.

```lua
vim.g["codegpt_text_popup_filetype"] = "markdown"
```

#### Popup commands

```lua
vim.g["codegpt_ui_commands"] = {
  -- some default commands, you can remap the keys
  quit = "q", -- key to quit the popup
  use_as_output = "<c-o>", -- key to use the popup content as output and replace the original lines
  use_as_input = "<c-i>", -- key to use the popup content as input for a new API request
}
vim.g["codegpt_ui_commands"] = {
  -- tables as defined by nui.nvim https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup#popupmap
  {"n", "<c-l>", function() print("do something") end, {noremap = false, silent = false}}
}
```

#### Popup layouts

```lua
vim.g["codegpt_popup_options"] = {
  -- a table as defined by nui.nvim https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup#popupupdate_layout
  relative = "editor",
  position = "50%",
  size = {
    width = "80%",
    height = "80%"
  }
}
```

#### Popup border

```lua
vim.g["codegpt_popup_border"] = {
  -- a table as defined by nui.nvim https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup#border
  style = "rounded"
}
```
#### Popup window options

``` lua
-- Enable text wrapping and line numbers
vim.g["codegpt_popup_window_options"] = {
  wrap = true,
  linebreak = true,
  relativenumber = true,
  number = true,
}
```

#### Move completion to popup window

For any command, you can override the callback type to move the completion to a popup window. An example below is for overriding the `completion` command.

```lua
require("codegpt.config")

vim.g["codegpt_commands"] = {
  ["completion"] = {
    callback_type = "code_popup",
  },
}
```

### Horizontal or vertical split window
If you prefer a horizontal or vertical split window, you can change the popup type to `horizontal` or `vertical`.

```lua
-- options are "horizontal", "vertical", or "popup". Default is "popup"
vim.g["codegpt_popup_type"] = "horizontal"
```

To set the height of the horizontal window or the width of the vertical popup, you can use `codegpt_horizontal_popup_size` and `codegpt_horizontal_popup_size` variables.

```lua
vim.g["codegpt_horizontal_popup_size"] = "20%"
vim.g["codegpt_vertical_popup_size"] = "20%"
```

### Miscellaneous Configuration Options

``` lua

-- Open API key and api endpoint
vim.g["codegpt_openai_api_key"] = os.getenv("OPENAI_API_KEY")
vim.g["codegpt_chat_completions_url"] = "https://api.openai.com/v1/chat/completions"
vim.g["codegpt_llm_api_provider"] = "OpenAI" -- or Azure

-- clears visual selection after completion
vim.g["codegpt_clear_visual_selection"] = true
```

## Callback Types
Callback types control what to do with the response

| name      | Description |
|--------------|----------|
| replace_lines | replaces the current lines with the response. If no text is selected it will insert the response at the cursor. |
| text_popup | Will display the result in a text popup window. |
| code_popup | Will display the results in a popup window with the filetype set to the filetype of the current buffer |


## Template Variables
| name      | Description |
|--------------|----------|
| language |  Programming language of the current buffer. |
| filetype |  filetype of the current buffer. |
| text_selection |  Any selected text. |
| command_args | Command arguments. |
| filetype_instructions | filetype specific instructions. |


# Example Configuration

Note that CodeGPT should work without any configuration.
This is an example configuration that shows some of the options available:

``` lua

require("codegpt.config")

-- Override the default chat completions url, this is useful to override when testing custom commands
-- vim.g["codegpt_chat_completions_url"] = "http://127.0.0.1:800/test"

vim.g["codegpt_commands"] = {
  ["tests"] = {
    -- Language specific instructions for java filetype
    language_instructions = {
        java = "Use the TestNG framework.",
    },
  },
  ["doc"] = {
    -- Language specific instructions for python filetype
    language_instructions = {
        python = "Use the Google style docstrings."
    },

    -- Overrides the max tokens to be 1024
    max_tokens = 1024,
  },
  ["code_edit"] = {
    -- Overrides the system message template
    system_message_template = "You are {{language}} developer.",

    -- Overrides the user message template
    user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nEdit the above code. {{language_instructions}}",

    -- Display the response in a popup window. The popup window filetype will be the filetype of the current buffer.
    callback_type = "code_popup",
  },
  -- Custom command
  ["modernize"] = {
    user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nModernize the above code. Use current best practices. Only return the code snippet and comments. {{language_instructions}}",
    language_instructions = {
        cpp = "Use modern C++ syntax. Use auto where possible. Do not import std. Use trailing return type. Use the c++11, c++14, c++17, and c++20 standards where applicable.",
    },
  }
}

```

# Goals
* Code related usages.
* Simple.
* Easy to add custom commands.
