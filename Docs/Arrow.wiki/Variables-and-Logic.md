
Arrow comes with a wide variety of features that make it a powerful tool for
design and development of non-linear interactive documents for many creative purposes 
specially production of story-rich games.

*Variables* and nodes such as [User-Input], [Variable-Update], [Condition], etc.,
are some of these features, helping developers to introduce logic to their projects,
within a fully visual development environment.

In this document, we review the most important features that help extending the logic side of your work.

> Make sure to check wiki pages on [built-in nodes][builtin-nodes] as well.
> Also browse documentation on *[Characters]* to know more about their interesting potentials.


## Basics

There are three kinds of variables in Arrow:

+ Numbers (num) which hold an integer
+ Booleans (bool) which hold a binary state (i.e. `True` or `False`)
+ Strings (str) which hold text

Variables in Arrow are global to the document, so every scene and node can read or write them.

To create a variable switch to the respective tab in the *Inspector* panel.

> You may need to use arrow buttons on top-right corner of the tab-bar
> to bring other tabs into view, or use the selector button on the panel's titlebar.

You can create and modify initial value of any variable there,
but remember, you need to press the `set` button to keep changes.


## Variable Modification

We can modify current value of any variable in runtime, using modifier nodes:

+ [User-Input] nodes show customizable prompt messages and input controls (with validation),
then replace current value of their target variable with the input they receive from the player.

+ [Variable-Update] nodes modify current value of their target variable.
Any variable type has its own set of operations and type-casting is not supported.    
Some operations accept another variable as the right-hand side of the formula;
in that case if you select the same variable, the initial value of the variable will be used as rhs.

+ [Generator] nodes can create and set value for any variable in the runtime.
There are different methods for value generation, depending on the target variable's type.
Each of these methods has a set of editable options/rules that define how the value is created.
For example, an integer can be made randomly from a range and may be limited to odd or even numbers.


## Variable Exposure (Parsing)

To expose a variable in node-types with text fields including [Dialog], [Interaction], [Content], etc.
use the variable's name in curly brackets, that is a mustache placeholder resembling `{variable_name}`.
When such nodes are being played, the Arrow console and any compatible runtime
will replace them with current value of the variable.

Take the following piece of text content as an example:

```
Hi {HERO_NAME}!
I'm RxD{ROBOT_CODE}, your robotic guide.
```

It will be translated to the next block,
if current value of `HERO_NAME` (str) is `Luke`
and `ROBOT_CODE` (num) is `7` :

```
Hi Luke!
I'm RxD7, your robotic guide.
```

Generally speaking, naming variables is your decision to make.
We suggest adhering to a convention, like always using meaningful names in snake_case.
Yet Arrow editor may force a few limitation to your variable names.
It may replacing some characters to make names exposure safe, namely to avoid curly brackets, dots, and similar,
or affix names with extra characters (by default an underscore `_`) to prevent duplication.

> Thanks to Continuum Safety under the hood, if you rename a variable,
> Arrow revises all its exposures for you automatically.


## Condition Nodes

[Condition] nodes compare current value of their target variables

+ to a specified value,
+ to current value of another variable
+ or to the initial value of the variable itself

in runtime.

Condition nodes compare current state of their target variables using typed operators.
For example a number can be checked if it's greater, lesser or equal to another number,
while strings can be checked for their length or matching a pattern;
but we can't compare a number with a boolean or string even the number's text representation.
In other words, automatic parsing or type-casting is not supported.


## Usage

Adding logic to your Arrow adventures, can advance them to higher levels of interactivity.
Yet you may not need Variables, their modifiers or conditions everywhere.

Recommended approach is to use Arrow's [navigation] features to control sequences of events,
as much as possible. These features are much easier to use and maintain, and are much more performant.

Take advantage of logic when the story needs to control some values such as inventory, score, etc.
For example, you can define HP (health points) variables for your players or characters
and update them after each combat; then you may use [Condition] nodes to see whether they are still alive
(`HP > 0`) or you need to [Jump] the player to the afterlife scene and resurrect them!

> Quick Tip!  
> If you intend to check a variable many times in your story, or need a repeatable block of logic,
> create a Macro and reuse it as many times as you like via [Macro-Use] nodes.


## See also:

+ [Characters] for their interesting ways of extending game logic with tags.



<!-- References -->
[builtin-nodes]: ./home#built-in-nodes
[User-Input]: ./user-input
[Variable-Update]: ./variable-update
[Generator]: ./generator
[Condition]: ./condition
[Characters]: ./characters
[Dialog]: ./dialog
[Interaction]: ./interaction
[Content]: ./content
[navigation]: ./navigation-and-plot-management
[Jump]: ./jump
[project-organization]: ./project-organization
[Macro-Use]: ./macro-use
