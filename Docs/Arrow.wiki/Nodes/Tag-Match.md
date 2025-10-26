
*Tag-Match* nodes are designed to act as non-binary branching gates, quite similar to a `switch` statement.

They match current value for a certain tag (known by its key) of a [Character][Characters]'s,
in play-time memory (of console or runtime), against a list of *patterns* defined in the node's data.
These patterns can be simple text (for quick exact match checks) or RegExp if the respective parameter is set active.

### Conventions:

+ Tag-Match is an automatic node: it does not wait for user interaction.

+ If skipped, a Tag-Match node plays its first connected outgoing slot
or the first one anyway if there is no connection.

+ Blank patterns are allowed by default, because tag values can be blank.
Be aware though that *an empty regular expression matches everything*.
Read [Use] section for more information.

+ For better user experience the keyword `--BLANK--` is always kept and interpreted as "" (empty String)
and is also used to display that value in the patterns list.

+ Blank tag keys and unset or invalid characters are not allowed and render the node invalid.

+ When the node is invalid, or no pattern matches, the node does end the plot line (EOL).
Check out [Use] section if you need a wildcard pattern passing anyway.

### Use:

Tag-Match nodes, can be used together with [Tag-Edit] and [Tag-Pass] nodes for event management.
Compared to [Tag-Pass] that has only two (true, false) outcomes and is capable of comparing multiple tags at once,
a matching node only checks one tag, while checking that one against multiple possible values, similar to a switch statement.

Imagine you are developing an adventure game with Arrow. In many scenes, characters talk about
their personal experiences. You want to offer different conversations depending on how they feel
about a situation (e.g. as a result of a previous [Dialog] choice hold in memory using a [Tag-Edit] node).
Feelings may not be binary, they can be sad, content, angry, etc.
We could check for this using multiple [Tag-Pass] nodes, and a tree of binary checks and branching outcomes
(i.e. checking if they are sad, and if not then checking if they are angry, and so on); but it can quickly get messy.
A better option is to check one tag against multiple possible values, let's say by having
a tag reflecting `_feeling_for_that_situation` matched against patterns such as [`mad`, `happy`, ...].

Thanks to RegExp support, each of these patterns can be more than a simple exact match check.
For example, if preferred, you can group multiple possible values to a single pattern (e.g. `happy|positive|cool`) and one outgoing slot,
or use an empty (blank) RegExp that will pass anything, as the last option to cover miscellaneous values in one slot and avoid EOL.

> RegExp patterns are very common and powerful. You can find many resources about their [concept][regexp-concept]
> and syntax,or tools to create and [test][regexp-test] them.
>
>> Technical Note:  
>> Arrow works on top of Godot with its RegExp implementation based on the [PCRE2][regexp-pcre2] library.  
>> You can find about PCRE2 [syntax][regexp-pcre2-syntax] and [more][regexp-pcre2-pat-ref] on their manual.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Characters]
    > To learn more about tag wizardry.
+ [Variables], [Variable-Update] & [Condition]
    > Another alternative for game-state and event management.
+ [Tag-Edit]
    > To dynamically create, remove or manipulate tags.
+ [Tag-Pass]
    > To create binary event gates, comparing collections of tags.



<!-- internal -->
[Use]: #use
<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Characters]: ./characters
[Tag-Edit]: ./tag-edit
[Tag-Pass]: ./tag-pass
[Dialog]: ./dialog
[Variables]: ./variables-and-logic
[Variable-Update]: ./variable-update
[Condition]: ./condition
<!-- absolute -->
[regexp-concept]: https://en.wikipedia.org/wiki/Regular_expression
[regexp-test]: https://regexr.com/
[regexp-pcre2]: https://www.pcre.org
[regexp-pcre2-syntax]: https://www.pcre.org/current/doc/html/pcre2syntax.html
[regexp-pcre2-pat-ref]: https://www.pcre.org/current/doc/html/pcre2pattern.html
