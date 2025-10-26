
*Interaction* node is a textual mean of branching and navigation.

This node type has a set of `actions`,
that will be presented to players, as decisions they can make,
to potentially alter their path forward and narrative outcomes.

### Conventions:

+ Skipped Interactions display nothing and play their first connected outgoing slot forward.

+ Unless being skipped, Interactions always wait for user interaction: a decision to be made.

+ The decided action will be played even if disconnected (i.e. EOL).

+ Interaction choices (actions) are expected to support minimal *BBCode* styling in their view.

+ [Variable] and [Character]-Tag exposure is supported in Interaction choices (actions).

+ Blank actions (i.e. with zero length) are not allowed.

### Use:

From just a behavioral point of view,
Interaction nodes resemble character-independent [Dialog] nodes,
that are always playable.

Although you can almost always achieve the same narrative function with Dialog nodes,
they are designed for a **semantically different** purpose.

Interaction do not need to be part of any conversation. Nothing is said, nothing is replied.
They are pure choices, presented to players. Providing decisions to be made deliberately,
taking different actions, possibly leading to different sub-plots or outcomes.

Having an independent node for that purpose, help us maintain a clear workflow,
in both terms of runtime development and creative design.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Dialog]
    > A similar but semantically different textual mean of branching.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Variable]: ./variable
[Character]: ./character
[Dialog]: ./dialog
