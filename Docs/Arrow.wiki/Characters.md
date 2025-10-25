
Character is one of the main resource types of Arrow,
wrapping a *name*, a *color* label, and any number of dynamic key-value *[tags]*.

Characters can be referenced by nodes, and are by few built-in ones.
This means we can track every resource that somehow relates to a character,
such as [Dialog] and [Monolog] nodes.

More excitingly, characters can encapsulate arbitrary properties as their [tags].
These are collections of `key:value` pairs that can be managed
initially (from the *Inspector* panel)
and/or dynamically at runtime.

Tags can also be exposed in different nodes such as [Content], [Interaction] etc.,
using `{character_name.tag_key}` placeholders.

> To create or edit a `Character` head to the respective tab of the `Inspector` panel.
> There you can also set the initial tag values.


## Tags

Tags are designed to be simple in implementation but highly flexible and dynamic.
They are `key: value` (all string) pairs of data encapsulated by a character resource.

> Tags are not independent resources. They do not have a UID and exist only
> as `key:value` entities under a character's `tag` collection/dictionary.

Unlike [Variables], Character tags only support string data, but more importantly,
they are managed dynamically at runtime. In other words,
**tags can be created on demand or get dropped/undefined**.
This means that you should be extra careful when removing a tag,
specially if they are supposed to be exposed somewhere in a node with text content.

### Common Uses & Potentials

+ Dynamic event management using [Tag-Pass] and [Tag-Edit] nodes

    A very common scenario in game narrative design is to limit events to certain conditions.
    For such cases you could always use variables;but when the number of criteria is considerably large,
    defining and managing many variables may be cumbersome.
    It is easier to define and manage such events with character tags;
    added, removed, or manipulated using [Tag-Edit] and checked with [Tag-Pass] nodes.
    
    > For more information and examples, check documentation on the mentioned nodes.

+ Data encapsulation and parsing

    In earlier Arrow versions we only had [Variables] to keep game data and expose them as pieces text.
    It would mean that to manage many related data you had to create many variables.
    The process and result wasn't necessarily neat and tidy.
    
    We can now create character resources to wrap and manage collections of data as `key: value` tags,
    even if the resource is not representing a story character in conventional definitions.
    For example, the game's inventory can be defined as a character.
    
    Character tags can be exposed in major built-in text nodes
    using mustache placeholders resembling `{character_name.tag_key}`.

    Common use for this feature is to assign data
    such as `name`, `alias`, `age`, `superpower`, `vehicle`, etc. to characters
    and use them anywhere those values are needed.
    Then we will only need to update a tag's value to have them all updated, even in runtime.
    
    We can manipulate tags with [Tag-Edit] nodes.
    
    > Tags only support String (text) keys and values,
    > for other data types [Variables] offer more advantages.
 
    > Parsing `{variable}`s inside tag values is not supported or advisable,
    > but may work as a side effect of some built-in node's internal mechanisms.

+ Tracking, referencing and citation

    Characters tab of the Inspector panel provides tracking functionalities
    which can list all the nodes referencing a particular character,
    or a tag (mustache placeholder) belonging to that character in their content.
    
    > These are sorted by the time a reference is made.
    
    You can take advantage of this feature for different purposes including following examples:

    + Locating Presence
        
        Imagine you want to locate nodes that are about a character named `Hero`,
        but you do not want to exactly expose any special tag (even `{Hero.name}`) in them.
        You can create a tag for Hero with an arbitrary key (e.g. `_` or any other convention you prefer),
        and no text (i.e. zero-length blank) value, then use it in those nodes' exposure-supporting text fields.
        The exposed blank values would not change player experience but you can always find those nodes
        because the inspector tracks them just like any other exposed tag.
        
        > That tag can be queried using global text search for `Hero._` (from status bar) as well.
    
    + Categorizing

        Alternatively you can use value-less (blank) tags with any arbitrary keys
        to categorize nodes. For example you can create blank tags such as
        `{Hero._love_affair}`, `{Hero._nightmares}`, `{Hero._battles}`
        to categorize different [Content], [Dialog], [Interaction], etc.
        These tags won't print any text to your players, but can be located
        and even better queried using global text search.

        > Another general way to categorize and locate nodes is to put category badges
        > (with any preferred format such as `[battle-scene]`) in their *node notes*
        > and query them using the global text search.

        > See also [Project Organization][project-organization]

### Hygiene!

**With great \[dynamic\] power comes great responsibility**

Undefined tags (including tags with no or invalid key _e.g. `{Hero.}`_)
can be exposed in many nodes, so be referenced and located by the inspector.
But unless created/defined at runtime or later in the inspector, 
they *will be printed as the placeholder text* they are,
not as values (because there is no real value).

This is the artist/dev's responsibility to make sure
that exposed tags do exist in memory,
whenever they are needed.

One generally good practice is to use placeholders, only for pre-set tags
(initialized in the editor) and never unset or remove them in runtime.

On the other hand, dynamically created (and removed) tags can be used
for event management as described above.



<!-- References -->
[tags]: #tags
[Dialog]: ./dialog
[Monolog]: ./monolog
[Content]: ./content
[Interaction]: ./interaction
[Variables]: ./variables-and-logic
[Tag-Pass]: ./tag-pass
[Tag-Edit]: ./tag-edit
[project-organization]: ./project-organization
