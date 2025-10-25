
*Entry* is not a narrative (textual) node type,
but a technically important navigational node.

Arrow console and any other runtime implementation,
need to know where to start each *Scene* (or *Macro*).
They also need to know which node is the beginning of the whole project.

Technically you can start from any node; but a specifically designed node, Entry,
can provide advantages, including the editor's checks needed for Continuum Safety.

They also have a `plaque` parameter, that helps identifying them easier.

### Conventions:

+ Entry is an automatic node: it does not wait for user interaction.

+ Whether skipped or not, Entry nodes always play their only outgoing slot.

+ There can only be one active Entry per Scene/Macro and one per Project document.
One instance can also be active for both.

### Use:

Although each project, scene, or macro,
only needs and accepts one active Entry node,
you can create as many of them as you wish.

Extra (deactivated) Entry nodes can act as clean starting points,
in case you have multiple almost independent plot-lines in one scene.
They can serve as focal targets for one or multiple [Jump] nodes as well.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Jump]
    > To navigate players into Entry points from independent branches.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Jump]: ./jump
