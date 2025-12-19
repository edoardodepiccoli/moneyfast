OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_API_KEY"] || ENV.fetch("OPENAI_API_KEY")
end
