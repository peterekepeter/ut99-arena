
# FFNArena

[![ci](../../workflows/ci/badge.svg)](../../actions/workflows/ci.yml)

Is a general use mutators capable of modifying the rules of the game:

 - replace any actor with any other actor
 - remove default inventory
 - shuffle weapons every N seconds (RandomArena)
 - prevent weapon drop
 - ammo regeneration
 - health regeneration
 - add starting inventory (Loadout)
 - modify damage and momentum values by a scalar
    - separate settings for team and self damage
 - remove bullet knockback effect (stun)
 - drop items in invetnory upon death

## Profiles

These configurations are called profiles. Profiles can be defined 
and loaded in multiple ways.

Static profiles are separate mutators numberred from 0 to 99 and
can be loaded by spawning in the specific mutator.

```sh
ucc server DM-Fractal?Mutator=FFNArena.Profile8
```

Additional profiles are avaiable by using URL parameters. For these
to work you need to add a base mutator `FFNArena.FFNArena` and you 
also need to specify which profile to load via a URL parameter.

```sh
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

After a profile is run for the first time it should generate an empty
profile entry in `FFNArena.ini` which you can then modify.

For example usage see the provide [FFNArena.ini](./FFNArena.ini)


## Debugging

By default all actions taken by FFNArena will be logged in server log.
For additional logs please enable `bDebugLog=True` flag. This will 
emit additional logs useful to understand what's happening.

You can also inspect and debug damage values `bDebugLogDamage=True`
will log all damage that's applied to actors. You can use this
log to fine-tune and check damage values.

To regenerate the config entries for a profile set `bFirstRun=True`


## Development

Recommended tools:
 - recommended editor [VsCodium](https://vscodium.com/) or [VsCode](https://code.visualstudio.com/)
 - enhanced language support [ucx](https://marketplace.visualstudio.com/search?term=ucx&target=VSCode)
 - build tool [ucx](https://www.npmjs.com/package/ucx) (link contains instrallation steps)
 - [tasks.json](.vscode/tasks.json) comes with preconfigured development tasks
 - [nodemon](https://nodemon.io/) is needed for watch tasks to work

To build from CLI run:

```sh
ucx build FFNArena
```

To test CLI run:

```sh
ucx build TestFFNArena && ucx ucc TestFFNArena.TestFFNArena
```
