
*Tag-Edit* nodes are used to create, remove or
manipulate Character-Tags in multiple ways.

Each Tag-Edit node accepts a tag key and a tag value,
and uses them to apply one of following editions
to its target `character`'s collection of tags:

+ **Inset**: Adds a `key:value` tag, only if the key does not exist.
+ **Reset**: Resets value of a tag, only if the key exists.
+ **Overset**: Overwrites or adds a `key:value` tag, whether the key exists or not.
+ **Outset**: Removes a tag from collection if both its key & value match the ones in edition.
+ **Unset**: Removes a tag if just its key matches the one in edition.

### Conventions:

+ Tag-Edit is an automatic node: it does not wait for user interaction.

+ Skipped Tag-Edit play their only outgoing slot forward,
without applying any change to current tag collection of their target character.

+ Complying with the character inspector, tag keys and values should be Strings;
but only values may be blank.

### Use:

Character-Tags are the only data type that we can create at runtime.
> Other resources such as [Variables], although mutable in runtime,
> should already exist with an initial value from the beginning.
This dynamism allows us to use them for temporary or undefined states,
or when we need to create and manage relatively large quantity of states, on demand.

One very common and powerful use for tags is in event management.
Tag-Edit nodes can set or unset virtually endless number of event flags,
passing through different branches;
then at the the right moment [Tag-Pass] nodes can check if any or all of flags
required to pass to a particular branch are set or not.

For example, you may intend to allow your player to pass the bloody gate and enter the final dungeon,
conditionally, if only the hero has slain a particular monster in a branch and learnt a magic word in another.
You can use Tag-Edit nodes to set tags with `slew_big_bad_monster` and `knows_magic_word` keys
in mentioned branches, respectively; then use Tag-Pass nodes here and there to check
if the hero has all mights (tag-keys) to pass.
> Of course you could use [Variables] with [Variable-Update] and few [Condition] nodes
> to achieve similar result with different ergonomics. Either way has its own pros and cons.
> This is completely your choice, use any approach you find fitting your workflow.

> Quick Tip!  
> If you intend to check for an event again and again, with complex (multi-pass) logic,
> consider creating a Macro and utilizing [Macro-Use] nodes.

> Check out [Characters] documentation,
> for more information about Tags and their other exciting uses.

### See also:

+ [Characters]
    > To learn more about tag wizardry.
+ [Variables], [Variable-Update] & [Condition]
    > Another alternative for game-state and event management.
+ [Tag-Match]
    > To create non-binary event gates, similar to a switch statement.
+ [Tag-Pass]
    > To create binary event gates, comparing collections of tags.



<!-- relative -->
[Characters]: ./characters
[Variables]: ./variables-and-logic
[Tag-Match]: ./tag-match
[Tag-Pass]: ./tag-pass
[Variable-Update]: ./variable-update
[Condition]: ./condition
[Macro-Use]: ./macro-use
