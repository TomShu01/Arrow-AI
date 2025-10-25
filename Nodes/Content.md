
*Content* nodes are great to display a long chunk of text in your narrative.

They accept a set of *all optional* parameters including:

+ Title
+ Content body
+ Brief (length)
+ Auto-play
+ Clear

The `title` and `content` body parameters are expected to be displayed to players.
Depending on the runtime implementation, they may have different styling and view.

The other parameter, `brief` length, is more of an Arrow editor's feature
that indicates how many characters from the beginning of the `content` body
shall be previewed on the grid view of the node. `-1` means all the text.
> A custom runtime can use this parameter for creative purposes such as collapsing content body.

When optional `auto`-play parameter is `true` (or if it is unset and default is `true`)
the content will play the next node automatically,
otherwise it will wait for user interaction to continue.

Content nodes can also optionally `clear` the view before being displayed to the player.
It specially targets text wall displays, if it is the way your runtime shows content.

### Conventions:

+ Skipped Content nodes take no action (print no text, do not clear the page),
and automatically play the next node (regardless of `auto` and `clear` parameters).

+ Both title and content body views are expected to support minimal *BBCode* styling.

+ [Variable] and [Character]-Tag exposure is supported for both title and content body parameters.

### Use:

Content nodes are easy, general-purpose and straightforward.
They can be used to give players information, scene descriptions,
or any other kind of content that has no specific node type.

> Quick Tip!  
> You can use `auto`-play parameter to create relatively larger or dynamic content body
> by conditionally mixing multiple atomic pieces of content.
>> It may also be a good idea to have the last part manually playable,
>> giving the user time to read your text.

### See also:

+ [Dialog]
    > For conversations or short monologs with possibility of branching.
+ [Monolog]
    > For long monologs (similar to Content but belonging to a character).
+ [Tag-Pass] and [Condition]
    > To conditionally show or mix Content nodes.



<!-- relative -->
[Variable]: ./variables-and-logic
[Character]: ./characters
[Dialog]: ./dialog
[Monolog]: ./monolog
[Tag-pass]: ./tag-pass
[Condition]: ./condition
