local OpenAIProvider = require("codegpt.providers.openai")
local AzureProvider = require("codegpt.providers.azure")

Providers = {}

function Providers.get_provider()
	local provider = vim.fn.tolower(vim.g["codegpt_openai_api_provider"])
	if provider == "openai" then
		return OpenAIProvider
	elseif provider == "azure" then
		return AzureProvider
	else
		error("Provider not found: " .. provider)
	end
end

return Providers
