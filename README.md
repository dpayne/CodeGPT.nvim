# CodeGPT.nvim

CodeGPT a plugin for neovim that provides commands to interact with ChatGPT. The focus is around code related usages, so code completion, refactorings, generating docs, etc.

## Installation

* Set environment variable `OPENAI_API_KEY` to your [openai api key](https://platform.openai.com/account/api-keys).
* The plugins plenary and nui are also required.

Installing with packer.

```lua
use("nvim-lua/plenary.nvim")
use("MunifTanjim/nui.nvim")
use("dpayne/CodeGPT.nvim")
```

Installing with plugged.

```vim
Plug("nvim-lua/plenary.nvim")
Plug("MunifTanjim/nui.nvim")
Plug("dpayne/CodeGPT.nvim")
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

| name | default | description |
|------|---------|-------------|
| model | "gpt-3.5-turbo" | The model to use. |
| max_tokens | 4096 | The maximum number of tokens to use including the prompt tokens. |
| temperature | 0.6 | 0 -> 1, what sampling temperature to use. |
| system_message_template | "" | Helps set the behavior of the assistant. |
| user_message_template | "" | Instructs the assistant. |
| callback_type | "replace_lines" | Controls what the plugin does with the response |
| language_instructions | {} | A table of filetype => instructions. The current buffer's filetype is used in this lookup. This is useful trigger different instructions for different languages. |

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

The default command configuration is

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

``` lua

-- Open API key and api endpoint
vim.g["codegpt_openai_api_key"] = os.getenv("OPENAI_API_KEY")
vim.g["codegpt_chat_completions_url"] = "https://api.openai.com/v1/chat/completions"

-- clears visual selection after completion
vim.g["codegpt_clear_visual_selection"] = true

-- Wraps the text for all filetypes in the popup window, this overrides the above setting
vim.g["codegpt_wrap_popup_text"] = true
```

## Callback Types
Callback types controls what to do with the response

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

Note CodeGPT should work without any configuration. This is an example configuration that shows some of the options available.

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
* Code related usages
* Simple
* Easy to add custom commands
