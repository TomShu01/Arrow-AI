
*Hub* nodes are very simple but useful navigation nodes that merge multiple branches,
by accepting multiple incoming connections (grid graph links)
and playing to only one outgoing slot.

The only parameter they have is the number of their incoming `slots`.

### Conventions:

+ Hub is an automatic node: it does not wait for user interaction.

+ Considering their natural purpose, Hub nodes expect at least two incoming slots.

+ Hubs fulfill their existential duty even skipped, and play their only slot out.

### Use:

Merging branches or outgoing links is the one simple task for which Hub nodes exist.

> If you intend to merge branches into another scene or a node far away on the grid,
> [Jump] nodes are proved very clean and useful.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Jump] & [Entry]
    > To navigate players into further away nodes or branches.
+ [Randomizer]
    > The exact opposite of a Hub.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Jump]: ./jump
[Entry]: ./entry
[Randomizer]: ./randomizer
