# April 2025

Increased static profile count to 100. These can be activates by one of
the static mutators to the server

```
ucc server DM-Fractal?Mutator=FFNArena.Profile8
```

Infinite dynamic profiles can be loaded
by using mutator together with URL parameter `FFNArena=ProfileName`

```
ucc server DM-Fractal?Mutator=FFNArena.FFNArena?FFNArena=Loaded
```

When this successfully activates you should see the following in the
server logs:

```
ArenaFFN: Using dynamic profile [Loaded] from FFNArena.ini
ArenaFFN: FFNArena.FFNArena Loaded with stuff!
ArenaFFN: ArenaFFNShuffle using advanced weapon switcher
ArenaFFN: loaded 8 weapons, 42 pickups for loadout
ArenaFFN: registered 0 replacement rules
```


# January 2022

## HealthRegen

Added ability to regenerate health for players.

```ini
    bRegenHealth=True
    RegenHealthTimer=1.000000
    RegenHealthAmount=1
    RegenHealthLimit=150
```

## AmmoRegen

Bugfix: AmmoRegen should only apply to players and bots.

