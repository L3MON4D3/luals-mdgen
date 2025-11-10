# Cat

This project models a cat. The cat can meow and eat, without limit.

* My doc:
  * `Cat.meow(target, volume)`: Make the cat meow at something, in some volume.
    * `target: string` What to meow at.
    * `volume: number` How loud to meow.
  * `Cat.eat(amount, foodname)`: Make the cat eat something.
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

      Demo-image:

      [eating_cat](https://balmesvet.com/wp-content/uploads/2025/05/4.jpg)

      invalid Demo-image:  
      Demo-link: <https://wikipedia.com>
  * ```lua
    print("lel")
    ```
  * `Cat.enemies(opts): boolean, string[]`: Return a list of enemies of all cats.
    * `opts: CatEnemiesOpts` Lots of options for cats' enemies.  
      Valid keys are:
      * `filter?: fun(string) -> boolean?` Optionally filter enemies by their name.
      * `max_legs: number` Only return enemies with this number of legs. Despite their legs, they may be less dangerous,
        so take care!
      * `min: number` Only return enemies with this number of legs.
      * `extra_opts: CatEnemiesExtraOpts` More opts!  
        Valid keys are:
        * `o1: number` First extra-opt.
          ```lua
          print("some text")
          ```

    This function returns:
    * `has_enemies: boolean` Whether the cat has enemies.
    * `enemies: string[]` List of enemie's names.
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
