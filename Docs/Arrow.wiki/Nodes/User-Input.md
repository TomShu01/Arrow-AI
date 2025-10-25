
*User-Input* node prompts player with a question
and set received answer to a [Variable].

Input (control) they show to players can be customized,
depending on their target `variable` type (i.e. number, string, boolean).
These `custom` settings include parameters used for appearance as well as input validation.

+ **Number**:
    + *Min* & *Max*: *Inclusive* upper and lower limits.
    + *Step*: Input distance from minimum limit, shall be a factor of this value.
    + *Value*: Default and/or preset value for the input (control).
+ **String**:
    + *Pattern*: Regular Expression that valid input shall match.
        > Blank patterns pass any value (not recommended).
        > Check out [Use] section for more information.
    + *Default*: Default and/or preset value for the input (control).
    + *Extra*: Information, hit/tooltip, placeholder, etc. depending on the runtime implementation.
+ **Boolean**:
    + *False* & *True*: Negative & Positive messages or option texts to customize input appearance.
    + *Preset State*: Default and/or preset value for the input (control).

### Conventions:

+ Skipped User-Input nodes display nothing and play their only outgoing slot forward,
without applying any change to current value of their target variable.

+ Unless being skipped, User-Input always waits for user interaction.

+ Players can not pass a User-Input node, unless their input is valid.
    > Default value may be forced, if due to technical limitations or design decisions,
    > runtime shall play after user interaction anyway, even with invalid input.
    > For numeral inputs, nearest valid value to the wrong input can be used as well.

+ Prompt (question) text is expected to support minimal *BBCode* styling.

+ [Variable] and [Character]-Tag exposure is supported in User-Input prompt (question) text.

### Use:

User-Input nodes are needed whenever we intend to receive inputs *directly* from players.

> We can use other node types such as [Interaction] coupled with [Variable-Update],
> to let players choose between different options (indirectly).

Direct inputs shall always be validated properly.

Imagine you want to let players choose their avatar name/alias using a string (text) input.  
You create a User-Input, select `hero_alias` as target [Variable], and later use it in textual nodes:  
"My name is {hero_alias}. Prepare to crack you egg monster!"  
If you add no *Pattern*, any value wil be passed. In that case a player can leave input blank and pass.  
What we get will be "My name is . Prepare to ...", which is not that desirable.  
Validation is always crucial. In this case you can customize input with many patterns including but not limited to:
+ `^[a-zA-Z]{3,7}$`: accepting any english alphabetical value with length of 3 to 7 characters (inclusively)
+ `^[\w]{1,}$`: accepting alphanumeric and underscore (i.e. a *word* in RegExp sense) with at least one character

Possibilities are virtually endless.

We can also get number input for `hero_age` or boolean input for `hero_is_on_egg_diet`
and use [Condition] node to navigate players to different branches, e.g. running from egg smell,
or trying to crack and cook the monstrously big egg!

Be creative as much as you like.
Let's use inputs with pattern validation for puzzles.
In a scene, our hero can enter the Smelly Egg Dungeon, only if he or she knows the secret egg-word.
The world is written on the big smelly gate in a puzzling limerick.
We can provide patterns such as following to accept the valid answer and let our hero pass:
+ `(?i)^eggshell|egg(\W)timer|easter(\W)egg$`: a set of acceptable egg-words
    > with `(?i)` modifier to accept case-insensitive input,
    > and `(\W)` for non-word (whitespace, dash, etc.) in some of the answers.
    >> We could use `(\W?)` to make it optional. Parenthesis is to group sections.
+ `(?i)^(egg)(\W?)(nog|roll|cream)$`: for egg-based edibles
+ `(?i)^((egg)(\W?)(plant|fruit))|canistel$`: a mix of both approaches

> String User-Input supports Regular Expression (RegEx or RegExp) for pattern validation.  
> They are very common and you can find many resources about their [concept][regexp-concept] and syntax,
> or tools to create and [test][regexp-test] them.
>
>> Technical Note:  
>> Arrow works on top of Godot with its RegExp implementation based on the [PCRE2][regexp-pcre2] library.  
>> You can find more about PCRE2 [syntax][regexp-pcre2-syntax] and [pattern][regexp-pcre2-pat-ref] on their manual.

### See also:

+ [Variable-Update]
    > To manipulate a variable based on another variable or a static value.
+ [Generator]
    > To set random or semi-random value to a variable.
+ [Condition]
    > To create binary gates, comparing variables and values.



<!-- internal -->
[Use]: #use
<!-- relative -->
[Variable]: ./variables-and-logic
[Character]: ./characters
[Interaction]: ./interaction
[Variable-Update]: ./variable-update
[Generator]: ./generator
[Condition]: ./condition
<!-- absolute -->
[regexp-concept]: https://en.wikipedia.org/wiki/Regular_expression
[regexp-test]: https://regexr.com/
[regexp-pcre2]: https://www.pcre.org
[regexp-pcre2-syntax]: https://www.pcre.org/current/doc/html/pcre2syntax.html
[regexp-pcre2-pat-ref]: https://www.pcre.org/current/doc/html/pcre2pattern.html
