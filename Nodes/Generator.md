
*Generator* nodes can create and set random or semi-random data
to current value of their respective target [Variables] (in play-time).

Depending on the target `variable`'s type,
the `method` parameter of the generator
defines which algorithm will be used for data generation.
Depending on the `method` different `arguments` are expected to exist as well.

All the required parameters are editable from the *Inspector* panel.

### Conventions:

+ Generator is an automatic node: it does not wait for user interaction.

+ Skipped Generators play their only outgoing slot forward,
without applying any change to current value of their target variable.

### Use:

Creating lucky gates, dice-rolling, randomly selecting a word from a list
(e.g. to be a characters name), etc. are few ways we can use this node type.

In general, Generators may be used to add randomness (luck) or variance to a game-state.

### See also:

+ [User-Input]
    > To receive validated input from player and set it to a variable.
+ [Variable-Update]
    > To manipulate a variable based on another variable or a static value.
+ [Condition]
    > To create binary gates, comparing variables and values.



<!-- relative -->
[Variables]: ./variables-and-logic
[User-Input]: ./user-input
[Variable-Update]: ./variable-update
[Condition]: ./condition
