
*Variable-Update* nodes modify current value of their target variable (in play-time).

Any [Variable] type has its own set of operations (type-casting is not supported).
Most operations accept either static value or another variable as the right-hand side of the formula.
If you select the the target again, the initial value of the variable will be used as rhs.

All the required parameters are editable from the *Inspector* panel.

### Conventions:

+ Variable-Update is an automatic node: it does not wait for user interaction.

+ Skipped Variable-Update nodes play their only outgoing slot forward,
without applying any change to current value of their target variable.

### Use:

Variable-Update nodes are very useful. Possibilities are endless.
In general they are used anywhere we want to change a game-state
without direct user input.

One common scenario is to chain Variable-Update nodes
with branching nodes such as [Dialog] or [Interaction].

For example we can provide players with following interaction choices: 1. Slay the monster 2. Spare the enemy.  
Each of these actions could be connected to a Variable-Update node, or a different series of them
updating `hero_kindness`, `hero_combat_score`, etc. depending on the player's decision.

> For complex repeatable logic, consider Macros and [Macro-Use] nodes.

### See also:

+ [User-Input]
    > To receive validated input from player and set it to a variable.
+ [Generator]
    > To set random or semi-random value to a variable.
+ [Condition]
    > To create binary gates, comparing variables and values.



<!-- relative -->
[Variable]: ./variables-and-logic
[Dialog]: ./dialog
[Interaction]: ./interaction
[Macro-Use]: ./macro-use
[User-Input]: ./user-input
[Generator]: ./generator
[Condition]: ./condition
