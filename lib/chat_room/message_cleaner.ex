defmodule ChatRoom.MessageCleaner do
  use GenServer
  require Logger
  alias Phoenix.PubSub

  @cleanup_interval :timer.hours(1) # Check every hour

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_messages()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_messages do
    Logger.info("Starting message cleanup")
    expiration_time = NaiveDateTime.utc_now() |> NaiveDateTime.add(-24, :hour)
    PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:cleanup_messages, expiration_time})
  end
end
