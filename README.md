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
- Node.js (for asset compilation)
- Docker (for building the deployment image)
- Fly.io CLI (for deployment)

## Local Development Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/chat_room.git
   cd chat_room
   ```

2. Install dependencies:
   ```
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. Start the Phoenix server:
   ```
   mix phx.server
   ```

4. Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Deployment to Fly.io

This project is configured for deployment to Fly.io. Follow these steps to deploy:

1. Install the [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/)

2. Login to Fly.io:
   ```
   fly auth login
   ```

3. Create a new Fly.io app:
   ```
   fly launch
   ```
   This will create a new app and generate a `fly.toml` file.

4. Set the secret key base:
   ```
   fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
   ```

5. Deploy the application:
   ```
   fly deploy
   ```

6. Open your deployed application:
   ```
   fly open
   ```

## Project Structure

```
chat_room/
├── assets/              # Frontend assets (JS, CSS)
├── config/              # Application configuration
├── lib/
│   ├── chat_room/       # Core application logic
│   └── chat_room_web/   # Web-related modules (controllers, views, etc.)
│       ├── live/        # LiveView modules
│       │   └── chat_live.ex
│       ├── components/  # Reusable UI components
│       └── endpoint.ex  # Phoenix endpoint
├── priv/                # Private application files
├── test/                # Test files
├── Dockerfile           # Docker configuration for production
├── fly.toml             # Fly.io configuration
├── mix.exs              # Project and dependency configuration
└── README.md            # This file
```

## Key Files for Deployment

- `Dockerfile`: Defines the container image for the application.
- `fly.toml`: Configuration file for Fly.io deployment.
- `config/runtime.exs`: Runtime configuration, including production settings.

## Customization

You can customize the chat room by modifying the following files:

- `lib/chat_room_web/live/chat_live.ex`: Main LiveView module for the chat functionality.
- `assets/css/app.css`: Styling for the chat interface.
- `config/config.exs`: Application-wide configuration.

## Troubleshooting

If you encounter issues during deployment:

1. Check the Fly.io logs:
   ```
   fly logs
   ```

2. Ensure all environment variables are set correctly:
   ```
   fly secrets list
   ```

3. Verify your `Dockerfile` and `fly.toml` are correctly configured.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.