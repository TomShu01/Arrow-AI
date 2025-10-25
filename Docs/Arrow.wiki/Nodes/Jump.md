
Jump is another technically important navigational node type.

Arrow's editor is designed with authors and artists in mind,
so takes a graph (node-and-link) or no-coding development approach extensively.
Nodes (the most common resources) are mainly organized on a grid
and connected using graph links, creating series that define in what order these building blocks will be played.

There should as well be a way to connect nodes that are not on the same grid
(i.e. nodes on different scenes), or nodes that are on the same grid but far away
(where a normal graph link just wouldn't look nice).

Here shines *Jump* node type.

A Jump node accepts another node's *name* (user-editable UID),
internally finds the respective underlying immutable UID, and keeps it as the `target`,
so maintains a valid working link even if the destination node is renamed later.

Jump instances show their destination `name` and their `reason` label on their grid node view
helping to better visualize each Jump and its purpose.

When a Jump node is played, it immediately plays its target node forward.

### Conventions:

+ Jump is an automatic node: it does not wait for user interaction.

+ Skipped and invalid or unset Jump nodes would play nothing forward (i.e. EOL).

+ Jumping to another Jump is considered an *unsafe operation*
therefore *unexpected behavior* that may or may not be handled.

+ Jumping to a node that belongs to a macro would cause that macro to be treated as a normal scene.
    > If you intend to play a macro from beginning to end, try recommended way: [Macro-Use].

### Use:

Inputting another node's `name` in the destination field of a Jump inspector is all you need to do.
If the name is exact, the job is done. For partial names, the inspector does a search and provides you
with a list of nodes having that substring in their names. You can then select one from the list.

> If the grid node shows no change in destination or the inspector field resets,
> the data is either not (auto-) updated, or the inputted name is invalid.

Assigning a reason to each Jump is optional, but recommended,
specially if the destination node's name is not meaningful enough.

`Alt + Double-Click` on the grid Jump node
will change grid view to focus on the destination node.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Project Organization][project-organization]
+ [Entry]
    > A clean destination node type, specially when it is a focal/folding point
    > for multiple jumps or beginning of an independent plot-line. 
+ [Macro-Use]
    > Recommended way to play all nodes in a macro (a reusable scene) from Entry to EOL.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[project-organization]: ./project-organization
[Entry]: ./entry
[Macro-Use]: ./macro-use
