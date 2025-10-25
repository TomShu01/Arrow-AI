
*Tag-Pass* nodes are designed to act as binary gates.

They compare current collection of a [Character][Characters]'s tags in play-time memory
(of console or runtime), to another set of tags (criteria) defined in the node's data.

There are following comparison methods:

+ **Any (OR)**: If at least one of the tags matches, it short-circuits and passes positively.
+ **All (AND)**: All tags shall match for the node to pass positively.

To consider a tag from the character's, matching a tag in the criteria,
the node first checks if the criterion key exists in the character's current tags.
If the key is identical (case sensitively), then the value is checked to be identical,
whether blank or not.

Note that we can set any criterion tag to be a key-only check.
In that case any value would pass for that particular criterion tag.

### Conventions:

+ Tag-Pass is an automatic node: it does not wait for user interaction.

+ By convention, skipped Tag-Pass nodes will try to play their `False` slot first.
If there is no outgoing connection on that slot, the `True` slot will be played.

+ Complying with the character inspector, tag keys and values should be Strings;
but only values may be blank.

### Use:

Tag-Pass nodes are commonly used together with [Tag-Edit] nodes for event management.

Imagine you are developing an adventure game with Arrow. In many scenes, characters talk about
their personal experiences. You want to make all the conversations accurate and meaningful,
so you need your characters to remember what they have already told to one another and build up
their understanding on top of previous chats. One of the interesting things you planned for your game
is to allow different conversations to shape and re-shape, based on player's previous choices of [Dialog] lines.
In other words, if characters talk about a particular personal fact, that knowledge should change their future discussions.
In this project, we can set different tags when any personal fact is discussed;
then check for them later, in order to navigate players to the proper branch(s)
where sides of the conversation know about that fact.

For example we have a scene, in which character X asks why character Y looks so grumpy!  
Y may reveal that he has recently lost a dear one, or just pretend nothing is wrong.  
We may set this tag here for the character: `lost_companion` (with arbitrary or blank value)
if our player decides for Y to open up.  
X asks for more details if the fact is not ignored by Y: "A family member ?".  
Now we present our player with two choices via a playable Dialog node
: 1. "My Dog. He was family.", 2. "A friend actually.".  
Depending on the player's choice, we can update that tag to `lost_companion: pet`.  
The conversation continues and we may learn a lot more about both sides.  
We may also navigate players to decide a value for the new `lost_pet_name` tag, if Y was willing to talk about it.   
Few scenes later, they are walking together and meet a kid trying to find shelter for his newborn puppies.  
Y stops and silently stares at the cute little pups.  
Here we can check for tags and branch to different possible conversations.  
If `lost_companion: pet` and `lost_pet_name: Chucky` are set (all),
we can pass to the Dialog node including this line:
"Can any of these babies be the {Y.lost_pet_name} junior?";
otherwise into another branch with the Dialog line:
"What was your dog's name dear?" if we have at least `lost_companion: pet` set.  
We could have an all different scene if none of those tags where set.

> Of course you could use [Variables] with [Variable-Update] and few [Condition] nodes
> to achieve similar result with different ergonomics. Either way has its own pros and cons.
> This is completely your choice, use any approach you find fitting your workflow.

> Quick Tip!  
> If you intend to check for an event again and again, with complex non-binary logic,
> consider creating a Macro and utilizing [Macro-Use] nodes and/or [Tag-Match]s with multiple patterns.

> Check out [Characters] documentation,
> for more information about Tags and their other exciting uses.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Characters]
    > To learn more about tag wizardry.
+ [Variables], [Variable-Update] & [Condition]
    > Another alternative for game-state and event management.
+ [Tag-Edit]
    > To dynamically create, remove or manipulate tags.
+ [Tag-Match]
    > To create non-binary event gates, similar to a switch statement.



<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Characters]: ./characters
[Tag-Edit]: ./tag-edit
[Tag-Match]: ./tag-match
[Dialog]: ./dialog
[Variables]: ./variables-and-logic
[Variable-Update]: ./variable-update
[Condition]: ./condition
[Macro-Use]: ./macro-use
