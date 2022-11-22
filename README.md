# Blackjack

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Draft Multiplayer Blackjack Architecture

![link](../blackjack/priv/static/images/blackjack_liveview_architecture.png)

## Draft Game Server States

1. No players has taken a seat, no game in progress, no previous games
* note: there might be lots of players watching on the side line aka: client connections established

```
{
  dealer: { cards: []}
  players: list of players - empty - holds just the player id?
  totalSeatsRemaining: 3
  cards: full deck of 52 cards
  isGameInProgress: false
  completedGames: 0 // track the number of games played
  seat1: nil // holds the entire player state?
  seat2: nil
  seat3: nil
}

```

2. 2 player have taken a seat, no game start yet, no previous games, (start game button is visible now)

```

{
  dealer: { cards: []}
  players: []
  totalSeatsRemaining: 2
  cards: full deck of 52 cards
  isGameInProgress: false
  completedGames: 0 // track the number of games played
  seat1: {}
  seat2: {}
  seat3: nil
}

```

3. game started, and is waiting for 

### Player state

```
{
  playerId: ,
  player_name: random_name
  cards: [],

}

```




