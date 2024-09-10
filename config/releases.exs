# config/releases.exs
import Config

config :chat_room, ChatRoomWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 443],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Optional database configuration
# config :chat_room, ChatRoom.Repo,
#   url: System.get_env("DATABASE_URL"),
#   pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
