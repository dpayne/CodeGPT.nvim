local OpenAIProvider = require("codegpt.providers.openai")
local AzureProvider = require("codegpt.providers.azure")
local AnthropicProvider = require("codegpt.providers.anthropic")

Providers = {}

function Providers.get_provider()
	local provider = vim.fn.tolower(vim.g["codegpt_llm_api_provider"])
	if provider == "openai" then
		return OpenAIProvider
	elseif provider == "azure" then
		return AzureProvider
	elseif provider == "anthropic" then
		return AnthropicProvider
	else
		error("Provider not found: " .. provider)
	end
end

return Providers
