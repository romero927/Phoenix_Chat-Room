# lib/chat_room_web/live/chat_live.ex

defmodule ChatRoomWeb.ChatLive do
  use ChatRoomWeb, :live_view
  alias Phoenix.PubSub
  require Logger

  @idle_timeout 300_000 # 30 seconds

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(ChatRoom.PubSub, "chat_room")
      Logger.info("Client connected and subscribed to chat_room")
    end
    {:ok, assign(socket, messages: [], username: nil, users: %{}, online_users: [], status: "online", status_message: "", last_activity: System.monotonic_time(:millisecond))}
  end

  @impl true
  def handle_event("set_username", %{"username" => username}, socket) do
    if username && username != "" do
      unique_username = get_unique_username(socket.assigns.users, username)
      users = Map.put(socket.assigns.users, unique_username, %{status: "online", status_message: ""})
      timestamp = NaiveDateTime.utc_now()
      notification = %{
        id: System.unique_integer([:positive]) |> to_string(),
        type: :notification,
        content: "#{unique_username} has joined the chat",
        timestamp: timestamp
      }
      PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:new_user, unique_username, notification})
      Process.send_after(self(), :check_idle, @idle_timeout)
      Logger.info("New user set: #{unique_username}")
      {:noreply, assign(socket, username: unique_username, users: users, status: "online", status_message: "", last_activity: System.monotonic_time(:millisecond))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if message && message != "" do
      message_data = %{
        id: System.unique_integer([:positive]) |> to_string(),
        type: :user_message,
        username: socket.assigns.username,
        content: message,
        timestamp: NaiveDateTime.utc_now(),
        deleted: false,
        deleted_by: nil
      }
      PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:new_message, message_data})
      update_user_status(socket, "online", socket.assigns.status_message)
      {:noreply, socket |> push_event("clear_input", %{}) |> assign(last_activity: System.monotonic_time(:millisecond))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_message", %{"id" => id}, socket) do
    Logger.info("Delete message event received for id: #{id}")
    PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:delete_message, id, socket.assigns.username})
    Logger.info("Delete message broadcast sent for id: #{id}")
    {:noreply, assign(socket, last_activity: System.monotonic_time(:millisecond))}
  end

  @impl true
  def handle_event("leave_chat", _, socket) do
    if socket.assigns.username do
      notification = %{
        id: System.unique_integer([:positive]) |> to_string(),
        type: :notification,
        content: "#{socket.assigns.username} has left the chat",
        timestamp: NaiveDateTime.utc_now()
      }
      PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:user_left, socket.assigns.username, notification})
      PubSub.unsubscribe(ChatRoom.PubSub, "chat_room")
      Logger.info("User left: #{socket.assigns.username}")
      {:noreply, assign(socket, username: nil, messages: [], users: %{}, online_users: [], status: "online", status_message: "")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_status", %{"status" => status, "status_message" => status_message}, socket) do
    update_user_status(socket, status, status_message)
    {:noreply, assign(socket, status: status, status_message: status_message, last_activity: System.monotonic_time(:millisecond))}
  end

  @impl true
  def handle_event("user_active", _, socket) do
    if socket.assigns.status == "idle" do
      update_user_status(socket, "online", socket.assigns.status_message)
      {:noreply, assign(socket, status: "online", last_activity: System.monotonic_time(:millisecond))}
    else
      {:noreply, assign(socket, last_activity: System.monotonic_time(:millisecond))}
    end
  end

  @impl true
  def handle_info(:check_idle, socket) do
    time_since_last_activity = System.monotonic_time(:millisecond) - socket.assigns.last_activity

    cond do
      socket.assigns.status == "online" && time_since_last_activity >= @idle_timeout ->
        update_user_status(socket, "idle", "")
        {:noreply, assign(socket, status: "idle", status_message: "")}
      socket.assigns.status != "online" ->
        {:noreply, socket}
      true ->
        Process.send_after(self(), :check_idle, @idle_timeout)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message_data}, socket) do
    Logger.info("New message received: #{inspect(message_data)}")
    {:noreply, update(socket, :messages, fn messages -> messages ++ [message_data] end)}
  end

  @impl true
  def handle_info({:delete_message, message_id, username}, socket) do
    Logger.info("Delete message info received for id: #{message_id} by user: #{username}")
    updated_messages = Enum.map(socket.assigns.messages, fn
      %{id: ^message_id, type: :user_message} = message ->
        Logger.info("Marking message as deleted: #{inspect(message)}")
        %{message | deleted: true, deleted_by: username}
      message -> message
    end)
    {:noreply, assign(socket, messages: updated_messages)}
  end

  @impl true
  def handle_info({:new_user, username, notification}, socket) do
    Logger.info("New user joined: #{username}")
    users = Map.put(socket.assigns.users, username, %{status: "online", status_message: ""})
    online_users = [username | socket.assigns.online_users] |> Enum.uniq()
    {:noreply, assign(socket, users: users, online_users: online_users, messages: socket.assigns.messages ++ [notification])}
  end

  @impl true
  def handle_info({:user_left, username, notification}, socket) do
    Logger.info("User left: #{username}")
    users = Map.delete(socket.assigns.users, username)
    online_users = socket.assigns.online_users -- [username]
    {:noreply, assign(socket, users: users, online_users: online_users, messages: socket.assigns.messages ++ [notification])}
  end

  @impl true
  def handle_info({:user_status_update, username, status, status_message}, socket) do
    users = Map.update(socket.assigns.users, username, %{status: status, status_message: status_message}, fn user ->
      %{user | status: status, status_message: status_message}
    end)
    {:noreply, assign(socket, users: users)}
  end

  @impl true
  def handle_info({:cleanup_messages, expiration_time}, socket) do
    Logger.info("Cleaning up messages older than #{NaiveDateTime.to_string(expiration_time)}")
    updated_messages = Enum.filter(socket.assigns.messages, fn message ->
      NaiveDateTime.compare(message.timestamp, expiration_time) == :gt
    end)
    {:noreply, assign(socket, messages: updated_messages)}
  end

  defp get_unique_username(users, username) do
    if Map.has_key?(users, username) do
      number = 2
      get_unique_username_with_number(users, username, number)
    else
      username
    end
  end

  defp get_unique_username_with_number(users, username, number) do
    new_username = "#{username}#{number}"
    if Map.has_key?(users, new_username) do
      get_unique_username_with_number(users, username, number + 1)
    else
      new_username
    end
  end

  defp update_user_status(socket, status, status_message) do
    username = socket.assigns.username
    users = Map.put(socket.assigns.users, username, %{status: status, status_message: status_message})
    PubSub.broadcast(ChatRoom.PubSub, "chat_room", {:user_status_update, username, status, status_message})
    if status == "online", do: Process.send_after(self(), :check_idle, @idle_timeout)
    assign(socket, users: users)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-gray-100">
      <header class="bg-blue-600 text-white p-4 flex justify-between items-center">
        <h1 class="text-xl font-bold">Phoenix Chat Room</h1>
        <%= if @username do %>
          <div class="flex items-center">
            <span class="mr-4">
              Logged in as: <%= @username %>
              (<%= @status %><%= if @status_message != "", do: ": #{@status_message}" %>)
            </span>
            <button phx-click="leave_chat" class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition duration-200">
              Leave Chat
            </button>
          </div>
        <% end %>
      </header>

      <%= if @username do %>
        <div class="flex flex-1 overflow-hidden">
          <aside class="w-64 bg-white shadow-md flex flex-col">
            <div class="p-4 bg-blue-500 text-white">
              <h2 class="text-lg font-semibold">Online Users</h2>
            </div>
            <div class="flex-1 overflow-y-auto p-4">
              <%= for {user, user_data} <- @users do %>
                <div class="mb-2 flex items-center">
                  <div class={"w-2 h-2 rounded-full mr-2 #{if user_data.status == "online", do: "bg-green-500", else: "bg-yellow-500"}"}></div>
                  <span><%= user %></span>
                  <%= if user_data.status_message != "" do %>
                    <span class="ml-2 text-sm text-gray-500">- <%= user_data.status_message %></span>
                  <% end %>
                </div>
              <% end %>
            </div>
            <div class="p-4 border-t">
              <form phx-submit="update_status" class="flex flex-col">
                <select name="status" class="mb-2 p-2 border rounded" value={@status}>
                  <option value="online" selected={@status == "online"}>Online</option>
                  <option value="away" selected={@status == "away"}>Away</option>
                  <option value="busy" selected={@status == "busy"}>Busy</option>
                </select>
                <input type="text" name="status_message" placeholder="Status message" value={@status_message} class="mb-2 p-2 border rounded" />
                <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition duration-200">
                  Update Status
                </button>
              </form>
            </div>
          </aside>
          <main class="flex-1 flex flex-col">
            <div class="flex-1 overflow-y-auto p-4" id="chat-messages" phx-update="append">
              <%= for message <- @messages do %>
                <%= case message.type do %>
                  <% :notification -> %>
                    <div class="mb-4 text-center text-sm text-gray-500 italic" id={"notification-#{message.id}"}>
                      <%= message.content %>
                      <span class="text-xs ml-2">(<%= format_timestamp(message.timestamp) %>)</span>
                    </div>
                  <% :user_message -> %>
                    <div class={"mb-4 flex #{if message.username == @username, do: "justify-end"}"} id={"message-#{message.id}"}>
                      <div class={"max-w-xs lg:max-w-md xl:max-w-lg #{if message.username == @username, do: "bg-blue-500 text-white", else: "bg-gray-200 text-gray-800"} rounded-lg p-3 shadow"}>
                        <%= if message.deleted do %>
                          <p class="italic text-sm">
                            Message was deleted by <%= message.deleted_by || "unknown" %>
                          </p>
                        <% else %>
                          <p class="font-semibold mb-1"><%= message.username %></p>
                          <p><%= parse_urls(message.content) |> raw() %></p>
                          <p class="text-xs mt-1 opacity-75">
                            <%= format_timestamp(message.timestamp) %>
                          </p>
                          <%= if message.username == @username do %>
                            <button phx-click="delete_message" phx-value-id={message.id} class="text-xs text-red-300 hover:text-red-100 mt-2">
                              Delete
                            </button>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                <% end %>
              <% end %>
            </div>
            <div class="p-4 bg-white border-t">
              <form phx-submit="send_message" id="chat-form" class="flex">
                <input type="text" name="message" id="chat-input" placeholder="Type your message" class="flex-1 border rounded-l-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r-lg hover:bg-blue-600 transition duration-200">Send</button>
              </form>
            </div>
          </main>
        </div>
      <% else %>
        <div class="flex-1 flex items-center justify-center">
          <div class="w-full max-w-xs">
            <form phx-submit="set_username" class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
            <h2 class="text-2xl font-bold mb-6 text-center text-gray-800">Join the Chat</h2>
              <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="username">
                  Username
                </label>
                <input class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" id="username" type="text" name="username" placeholder="Enter your username" />
              </div>
              <div class="flex items-center justify-center">
                <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline transition duration-200" type="submit">
                  Join
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>

    <script>
      window.addEventListener("phx:clear_input", (e) => {
        document.getElementById("chat-input").value = "";
        document.getElementById("chat-input").focus();
      });

      // Scroll to bottom of chat messages
      const chatMessages = document.getElementById("chat-messages");
      if (chatMessages) {
        chatMessages.scrollTop = chatMessages.scrollHeight;
        const observer = new MutationObserver(() => {
          chatMessages.scrollTop = chatMessages.scrollHeight;
        });
        observer.observe(chatMessages, { childList: true });
      }

      // Reset idle timer on user activity
      ["mousemove", "keydown", "click", "scroll"].forEach(event => {
        document.addEventListener(event, () => {
          window.dispatchEvent(new CustomEvent("phx:user_active"));
        });
      });
    </script>
    """
  end

  defp format_timestamp(timestamp) do
    timestamp
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_string()
  end

  defp parse_urls(content) do
    url_regex = ~r/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)/
    Regex.replace(url_regex, content, fn url ->
      ~s(<a href="#{url}" target="_blank" rel="noopener noreferrer" class="text-blue-300 hover:text-blue-100 underline">#{url}</a>)
    end)
  end
end
