# Cat

This project models a cat. The cat can meow and eat, without limit.

* My doc:
  * `Cat.meow(target, volume)`:
    * `target: string` What to meow at.
    * `volume: number` How loud to meow.

    Make the cat meow at something, in some volume.
  * `Cat.eat(amount, foodname)`:
    * `amount: number` How much to eat.  
      The cat may eat a lot. Call like
      ```lua
      Cat:eat(5)
      ```
    * `foodname: string` What to eat.  
      May be any food a cat does not die from. For example
      01. appleaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      02. apple
      03. apple
      04. apple
      05. apple
      06. apple
      07. apple
      08. apple
      09. apple
      10. apple
      11. apple
      12. apple

    Make the cat eat something.
  * ```lua
    print("lel")
    ```
  * `Cat.enemies(opts)`:
    * `opts: CatEnemiesOpts` Lots of options for cats' enemies.  
      Valid keys are:
      * `filter: fun(string) -> boolean?` Optionally filter enemies by their name.
      * `max_legs: number` Only return enemies with this number of legs. Despite their legs, they may be less dangerous,
        so take care!
      * `min: number` Only return enemies with this number of legs.
      * `extra_opts: CatEnemiesExtraOpts` More opts!  
        Valid keys are:
        * `o1: number` First extra-opt.
          ```lua
          print("some text")
          ```

    Return a list of enemies of all cats.
  * lel lol  
    lul
    ```lua
    print("lel")
    ```

  ```lua
  print("lol")
  ```

# Other Animals?

Only cat for now.
