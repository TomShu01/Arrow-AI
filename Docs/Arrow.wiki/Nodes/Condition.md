
*Condition* nodes are designed to act as binary gates.

They compare current value of a [Variable] in play-time memory
(of console or runtime), to

+ a known static value
+ another variable's current value
+ or their own initial value

then decide if those left and right hand values match based on a certain criterion.

All these parameters can be edited by user.

Each variable type has its own set of supported criteria,
and only variables of the same type can be compared to each other.

If the match criterion is passed, the positive or `True`,
otherwise the negative or `False` outgoing slot will be played.

The (pseudo-) formula is show on the grid view of each node,
to represent the conditional statement.

### Conventions:

+ By convention, skipped Condition nodes will try to play their `False` slot first.  
If there is no outgoing connection on that slot, the `True` slot will be played.

+ Condition is an automatic node: it does not wait for user interaction.

### Use:

Common use for Condition nodes is to navigate players through branching stories,
based on designer's desired criteria and states that may change over play-time.
In other words controlling events based on variable game states.

For example, you can create a `player_rhetoric` (num) variable to track the score they get
for their diplomatic language. Then put a *Condition* gate that branches to two
different sub-plots if their score is higher or lower than a special value,
or another score you track such as `player_honesty`.

> Quick Tip!  
> You can use Condition nodes to version your work internally.  
> For example if your narrative includes mature content or violence,
> you can put those content behind conditional gates, that open only
> if the audience are of the right age and willing.

### See also:

+ [Navigation and Plot Management][navigation]
+ [User-Input]
    > To receive validated input from player and set it to a variable.
+ [Generator]
    > To set random or semi-random value to a variable.
+ [Variable-Update]
    > To manipulate a variable based on another variable or a static value.
+ [Tag-Pass]
    > Another powerful way of conditional event management.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Variable]: ./variables-and-logic
[User-Input]: ./user-input
[Generator]: ./generator
[Variable-Update]: ./variable-update
[Tag-Pass]: ./tag-pass
