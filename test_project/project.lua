---@class Cat
local Cat = {}

---Make the cat meow at something, in some volume.
---@param target string What to meow at.
---@param volume number How loud to meow.
function Cat:meow(target, volume) end

---Make the cat eat something.
---@param amount number How much to eat.  
---The cat may eat a lot. Call like
---```lua
---Cat:eat(5)
---```
---@param foodname string What to eat.  
---May be any food a cat does not die from. For example
---1. appleaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
---1. apple
function Cat:eat(amount, foodname) end

---@class CatEnemiesExtraOpts
---@field o1 number First extra-opt.
---```lua
---print("some text")
---```

---@class CatEnemiesOpts
---@field filter (fun(string): boolean)? Optionally filter enemies by their name.
---@field max_legs number Only return enemies with this number of legs.
---Despite their legs, they may be less dangerous, so take care!
---@field min number Only return enemies with this number of legs.
---@field extra_opts CatEnemiesExtraOpts More opts!

---Return a list of enemies of all cats.
---@param opts CatEnemiesOpts Lots of options for cats' enemies.
function Cat.enemies(opts) end
