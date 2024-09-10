defmodule ChatRoom.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatRoomWeb.Telemetry,
      {Phoenix.PubSub, name: ChatRoom.PubSub},
      ChatRoomWeb.Endpoint,
      ChatRoom.MessageCleaner
    ]

    opts = [strategy: :one_for_one, name: ChatRoom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ChatRoomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
