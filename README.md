# ZAP-TIMERS
These are simple Lua timers for Garry's Mod, with a pinch of optimization and love

# Benchmarks

idk how to accurately measure performance, so I roughly recorded the minimum FPS when creating 320,000 timers with 3 repetitions:

```lua
  for i = 1, 320000 do
        zapTimer.Create("hash"..i, math.Rand( 0.1, 0.2), 3, function() 
            a = a + 1
        end)
    end
```
On my PC I got:

Using gmod timers: ~28 FPS
Using zaptimers: ~48-57 FPS

