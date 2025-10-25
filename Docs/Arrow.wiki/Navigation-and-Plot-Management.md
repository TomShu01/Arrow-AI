
Plot management, the process of dividing your story/play to smaller scenes and/or sub-plots,
depends highly on your storytelling style as well as technical requirements such as runtime IO.

Navigation is another concept you may care about.
It's the way you pass your players (the audience) through different plots and sub-plots,
so they can interactively experience your game/story.

In this page, we'll take a look at the basic tools Arrow provides to help chart your story.


## Scenes and Jumps

Scenes and the graph-node system itself are the most fundamental Navigation and Plot Management features.

Each scene can contain arbitrary number of (sub-)plots, consisted of multiple linked graph nodes.

If a simple graphic link does not suffice, or you want to connect two faraway nodes while keeping the grid neat and tidy, the [Jump] nodes would come in handy.

Jump nodes can navigate players to any (destination) node, either in the same scene or any other one.
They do not have any outgoing connection; instead, they accept another node's name as their target parameter,
and when played (in console or runtime), continue the plot from another point by playing that target node.

When there is no target node, play finishes right at the point (i.e. EOL: End-of-line).

> You can rename target nodes without any problem, jump nodes use internal `UID`s to track their targets
> and adapt themselves automatically to the new names.

Generally, we recommend to keep scenes independent and as small as possible.
This is a good practice and makes development of huge projects easier.


## Branching & Refolding

Branching and Refolding are the main ingredients of a properly working interactive experience.

By branching a plot-line, you give your audience different paths to explore,
where a decision can change the story or the ending.

Arrow's main branching tools are [Interaction], [Dialog] and [Randomizer] nodes.

Interaction and Dialog nodes accept one incoming connection (or are jumped into)
and let user choose from a set of options.
Each of these options can navigate user to another node,
so another possible plot-line.

Randomizers do exactly what they are supposed to do. They get one incoming connection
and send player to a randomly selected outgoing connection.

Arrow provides more ways to introduce interactivity to your narrative via custom logic as well;
i.e. no-code programming, or combining variable-manipulator nodes with conditionals.

> To learn more, check out our wiki page on [Variables] and Logic.

Refolding or merging is the opposite of branching.
It's when you navigate players, so they end up in a deterministic focal node.
The main technical purpose of refolding is to limit or manage complexity of sub-plots by reducing possibilities.
In other words when you want some of independently growing sequences of story events, begun by different decisions,
to merge into a special event, so you can continue the rest of story with manageable number of possible futures.

Both [Hub] and [Jump] nodes are useful to refold your plots.
Hubs do merge their incoming graph links on the same scene into one outcome,
and Jumps are good when you want to merge branches from multiple different scenes.

> See also our wiki page on how to divide and [organize your projects][project-organization]
> into multiple `.arrow` chapter documents.



<!-- References -->
[project-organization]: ./project-organization
[Jump]: ./jump
[Interaction]: ./interaction
[Dialog]: ./dialog
[Randomizer]: ./randomizer
[Variables]: ./variables-and-logic
[Hub]: ./hub
