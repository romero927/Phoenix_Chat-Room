defmodule ChatRoom.UserTracker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def add_user(username) do
    GenServer.call(__MODULE__, {:add_user, username})
  end

  def remove_user(username) do
    GenServer.cast(__MODULE__, {:remove_user, username})
  end

  def get_users do
    GenServer.call(__MODULE__, :get_users)
  end

  @impl true
  def handle_call({:add_user, username}, _from, state) do
    if Map.has_key?(state, username) do
      {:reply, {:error, :username_taken}, state}
    else
      new_state = Map.put(state, username, true)
      {:reply, {:ok, username}, new_state}
    end
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:remove_user, username}, state) do
    {:noreply, Map.delete(state, username)}
  end
end
