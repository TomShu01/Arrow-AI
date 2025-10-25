
*Randomizer* nodes are very simple but useful nodes,
they split one incoming connection (grid graph link) into multiple outgoing ones.
One of those will be played forward randomly, each time the node is played.

The only parameter a Randomizer has is the number of its outgoing `slots`.

### Conventions:

+ Randomizer is an automatic node: it does not wait for user interaction.

+ Considering their natural purpose, Randomizer nodes expect at least two outgoing slots.

+ Randomizers fulfill their existential duty even skipped, and randomly play a slot anyway.

+ The randomly chosen slot will be played even if disconnected (i.e. EOL).

### Use:

You can use Randomizer to add variance to your narrative.
They can precede any set of nodes (similar but having deviations),
to create more colorful experience.

> If you like to update [Variables] with random or semi-random values,
> [Generator] node type may be a better option.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Hub]
    > The exact opposite of a Randomizer, merging multiple branches.



<!-- relative -->
[Variables]: ./variables-and-logic
[navigation]: ./navigation-and-plot-management
[Generator]: ./generator
[Hub]: ./hub
