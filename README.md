# Phoenix Anonymous Chat Room

This is a real-time, anonymous chat room application built with Phoenix LiveView. It allows users to join the chat with a username and exchange messages in real-time without requiring any database or user accounts.

## Features

- Anonymous chat: No user accounts or registration required
- Real-time messaging using Phoenix PubSub and LiveView
- User status management (online, away, busy, idle)
- Auto-idle functionality
- Clickable URLs in messages
- Message deletion
- Join/leave notifications with timestamps
- Online user list with status indicators
- Simple and intuitive user interface
- No database dependency

## Prerequisites

Before you begin, ensure you have the following installed:

- Elixir (version 1.14 or later)
- Erlang (version 24 or later)
- Phoenix Framework (version 1.7 or later)

## Installation

1. Clone the repository:
   ```
   git clone [https://github.com/yourusername/chat_room.git](https://github.com/romero927/Phoenix_Chat-Room)
   cd chat_room
   ```

2. Install dependencies:
   ```
   mix deps.get
   ```

3. Install and setup the asset pipeline:
   ```
   mix assets.setup
   ```

## Running the Application

To start the Phoenix server:

1. Start the server:
   ```
   mix phx.server
   ```

2. Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Usage

1. When you first open the application, you'll be prompted to enter a username.
2. After entering a username, you'll join the chat room.
3. Type your message in the input field at the bottom of the page and press "Send" or hit Enter to send a message.
4. All connected users will see your message in real-time.
5. You can update your status (online, away, busy) using the dropdown in the sidebar.
6. URLs in messages will be automatically converted to clickable links.
7. You can delete your own messages by clicking the "Delete" button next to them.
8. After 30 seconds of inactivity, your status will automatically change to "idle".

## Project Structure

```
chat_room/
├── assets/
├── config/
├── lib/
│   ├── chat_room/
│   │   └── application.ex
│   └── chat_room_web/
│       ├── components/
│       ├── live/
│       │   └── chat_live.ex
│       ├── router.ex
│       ├── telemetry.ex
│       └── endpoint.ex
├── priv/
│   └── static/
├── test/
└── mix.exs
```

## Key Technologies

- Phoenix Framework
- Phoenix LiveView
- Phoenix PubSub
- Tailwind CSS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Future Improvements

- Add support for emojis
- Implement private messaging
- Add chat rooms or channels
- Enhance security features

## License

This project is licensed under the MIT License.
