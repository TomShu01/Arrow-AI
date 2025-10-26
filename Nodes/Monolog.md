
*Monolog* nodes are to display long speeches, thoughts, and long partial conversations.

Compared to [Dialog] nodes, Monologs provide no branching. On the other hand,
they offer advantage of being textually advanced, akin to [Content] nodes.

> If you have short lines told by a character that lead to different branches [Dialog] is what you want.

Monolog nodes belong to a [Character].  
The required `character` can also be Anonymous (`-1`), although it's not recommended.

The second required parameter is `monolog` which is the character's expression,
and is expected to be shown to the player.

Other optional parameters include `brief` length, `auto`-play and `clear`.

The numeral (integer) parameter, `brief` length, is more of an Arrow editor's feature
that indicates how many characters from the beginning of the `monolog`
shall be previewed on the grid view of the node. `-1` means all the text.
> A custom runtime can use this parameter for creative purposes such as collapsing the long text.

When optional `auto`-play parameter is `true` (or if it is unset and default is `true`)
a Monolog node plays its next node immediately,
otherwise it waits for user interaction to continue.

Monolog nodes can also optionally `clear` the view before being displayed to the player.
It specially targets text wall displays, if it is the way your runtime shows content.

### Conventions:

+ Skipped Monolog nodes take no action (print no text, do not clear the page),
and automatically play the next node (regardless of `auto` and `clear` parameters).

+ Monolog text views are expected to support minimal *BBCode* styling.

+ [Variable] and [Character]-Tag exposure is supported for Monolog text.

### Use:

We can use Monologs to convey long contents that are expressed by a character.
It can be a long set of lines told by one side of a conversation,
a character's speech, a character's thoughts, etc.

> To create a full (multi-lateral) conversation, we can chain Monolog (and/or Dialog) nodes.

You can make any instance of Monolog node `auto`-play, regardless of the character being NPC or playable.
Think of this parameter as if you want to wait for user interaction or just continue.

> Quick Tip!  
> You can use `auto`-play parameter to create relatively larger or dynamic monolog
> by conditionally mixing multiple atomic Monologs.
>> It may also be a good idea to have the last part manual,
>> giving the user time to read your text.

### See also:

+ [Dialog]
    > An alternative when you need multiple playable lines and branching.
+ [Content]
    > For general purpose pieces of text (independent from characters).



<!-- relative -->
[Dialog]: ./dialog
[Content]: ./content
[Character]: ./characters
[Variable]: ./variable
