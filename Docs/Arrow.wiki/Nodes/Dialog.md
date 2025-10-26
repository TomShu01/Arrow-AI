
*Dialog* nodes are *partial conversations*.

In other words, each dialog node conveys one side of a conversation,
although the name might be a little misrepresenting.

This design together with playability option, makes Arrow conversation system much more flexible.

Dialog nodes belong to [Character]s.
Their `character` fields can be Anonymous (`-1`) too,
although it's not recommended.

These nodes accept one or multiple lines.
If optional `playable` parameter is `true` (or unset with default `true`)
the node will wait for player to choose a line,
otherwise a random line will be played.

### Conventions:

+ If skipped Dialog nodes play the first connected outgoing slot
or the first one anyway if there is no connection.

+ Dialog lines are expected to support minimal *BBCode* styling.

+ [Variable] and [Character]-Tag exposure is supported in Dialog lines.

+ Dialog nodes (unless skipped) will continue any disconnected line
being played by user interaction or randomly.
They consider it a deliberate designer/developer choice.
Naturally a disconnected outgoing slot will end the branch (i.e. EOL).

+ Blank lines (i.e. with zero length) are not allowed.

### Use:

Each line having an outgoing slot, means you can branch your story based on
a dialog line chosen by user, or create very detailed (ping-pong) discussions.

> To create a full (multi-lateral) conversation, you can chain Dialog (and/or [Monolog]) nodes.

> You can use a [Hub] if some or all of Dialog lines should forward to a singular next node.

You can make any instance of Dialog node playable, regardless of the character being NPC or playable.
Think of this parameter as if you want a line to be chosen by end-user, or randomly by machine.

### See also:

+ [Monolog]
    > An alternative when you need a singular long speech.
+ [Content]
    > For general purpose pieces of text (independent from characters).
+ [Interaction]
    > A similar but semantically different mean of branching.



<!-- relative -->
[Character]: ./characters
[Variable]: ./variable
[Monolog]: ./monolog
[Hub]: ./hub
[Content]: ./content
[Interaction]: ./interaction
