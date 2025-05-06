---@class Cat
local Cat = {}

---Make the cat meow at something, in some volume.
---@param target string What to meow at.
---@param volume number How loud to meow.
function Cat:meow(target, volume) end

---Make the cat eat something.
---@param amount number How much to eat.
function Cat:eat(amount) end

---Return a list of enemies of all cats.
function Cat.enemies() end
