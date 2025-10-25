
*Macro-Use* is a very handy tool to organize your project.
This node type allows to replay our reusable scenes known as macros,
as many times as we like, inside other normal scenes.

The only parameter they need is a `macro` UID.
For convenience, Macro-Use inspector provides a list of all available macros by name
(sorted by underlying UID normally reflecting creation time).

### Conventions:

+ Macro-Use is an automatic node: it does not wait for user interaction.

+ Skipped instances would not play their macro and just continue to their only outgoing slot.

+ If a macro being used ends normally (i.e. EOL), the parent scene will continue
form the next node connected to the container Macro-Use's only outgoing slot.

+ If a contained macro plays [Jump] internally, it remains contained.

+ If a contained macro plays [Jump] externally to a node in another scene,
it breaks the container, as if the macro is ended, but plays that destination node
instead of the container Macro-Use's outgoing slot.

### Use:

Macros (scenes that can live in other scenes)
are created from their own tab in the *Inspector* panel.
To (re-)use them in any other scene, create a Macro-Use node and select the desired macro's name
from the list provided by the node's inspector.

`Alt + Double-Click` on the grid node opens the macro (scene) in the editor.

One of the most common use for macros, is to let them act as functions or repeatable complex checkpoints.
Imagine you have a game with many battle scenes and you need to check if the player is still alive.
You can create a [Variable] or a [Character]-Tag to track the player's `health` status or HP
which is updated per battle.
Then create a macro that checks if `health` is low down to the afterworld.
Depending on the health state, this macro may jump to a game-over scene or do nothing and end the branch (EOL),
which let's the game continue normally form where the check macro is used forward.

This is a relatively simple check with few nodes.
Macros and Macro-Use will prove even more useful
as your project and its functions grow in complexity.
For example when you want to move the combat logic itself or its scoring into the function as well
(checking if there was a boss, updating health, stamina and skill scores based on exchanged damage, etc.).

### See also:

+ [Project Organization][project-organization]
+ [Navigation and Plot Management][navigation]
+ [Jump]
    > To link nodes on different scenes and jump between them independently.



<!-- relative -->
[project-organization]: ./project-organization
[navigation]: ./navigation-and-plot-management
[Jump]: ./jump
[Variable]: ./variables-and-logic
[Character]: ./characters
