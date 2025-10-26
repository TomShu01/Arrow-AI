
Importance of Project Organization increases with your project size.
Arrow comes with essential features to let users stay in control of their growing projects.
A lot of them, such as *Continuum Safety* and *Resource Tracking*,
work under the hood silently, so you can focus on the creative side of things.
But there are other matters you need to consider to keep things managed.
Dividing your project to multiple chapters (files/documents) or scenes,
creating macros for complex and repeatable logic, naming conventions you may follow,
how many authors may work on a single project document at the same time,
scope of shared resources, and many other subjects you should be aware of,
before your project gets monstrously big and out of control!

This document is about features and underlying functionalities
that help you rule your workflow, as your workspace grows.
It includes useful technical details
and some best practices as well.


## Continuum Safety

Imagine a very common scenario, where you have a focal node
that is used as the target node for a few [Jump] nodes from different scenes.
Due to a project being so big, one may not be able to track all the references,
and remove or replace that focal node, therefore making all the referring jumps invalid,
breaking the sequence of events and damaging continuity of the narrative.
That situation could only reveal itself as a headache in play-test or even production.

Arrow's continuum safety, to the rescue!

Continuum Safety is a core concept of Arrow editor.
You may experience it when the editor does not let you delete some nodes, macros, variables or characters.
You don't need to actively care about it because it is almost all automatic,
unless you are using relatively unsafe operations, such as jumping to another jump.

Under the hood, Arrow tracks most of the visible and invisible relations between resources.
Arrow knows that you have such jumps, so it prevents you from removing that used or referred destination node,
until you remove or change all the other user or dependent nodes too.

It works for all the main data types and built-in nodes including [Variables] and [Characters],
being the usage direct, such as in [Dialog] and [User-Input], or indirect,
via exposing mustache placeholders in text nodes such as [Monolog] or [Content].

You can check which nodes are depended on any resource
by looking for the reference locator (option button and arrows)
in the respective tab of the *Inspector* panel.
> If there is no dependent node, those buttons may not show up.


## Portability

From the ground up, Arrow has been developed to be as portable as possible.
It does not depend on any other tool being installed on your device.
It can run on a thumb-drive where your project files are,
or sit on the main device and switch between different working directories on demand.
It is even available as a [web app][web-app] that can store data in your browser.

### Configuration

Main configurations including work-directory, theme, history-size, etc.
are managed form *Preferences* panel.

> To access *Preferences* panel, press the `Arrow` menu button on top-left corner of the editor and select `Preferences`.

By default Arrow keeps its configurations as close to its executable as possible.
If its very own directory of residence is accessible, a `.arrow.config` file will be created;
otherwise local app directory (which depends on the user and OS) is the next place that will be tried.

You can also use following [CLI] argument to define a custom path to the directory
where Arrow keeps its config file, each time you run Arrow:

```shell
$ Arrow --config-dir '/home/USER/.config/'
```

> If you don't want any config file to be created, pass `--sandbox` argument instead.

### Work Directory & Switching

Arrow prioritizes the other way around for its work directory, where `.arrow.project` file is.
The place that Arrow editor looks for your files, is defined by your configurations (see above).
The default value for that would be local app directory; but you can change it from preferences menu.

You can override that with following [CLI] argument as well:

```shell
$ Arrow --work-dir '/home/USER/my_other_adventure/'
```

> Arrow considers each work-directory as an independent workspace.
> We can create a directory for each large project that would be divided into many documents.
> To switch between different work directories,
> just change the respective configuration from Preferences panel.
> Arrow automatically loads the existing `.arrow.project` or initializes a new one.
> You can also set Arrow to create each project's `.arrow.config` file in its own directory
> and switch between them on run, specially if you want to open multiple instances of Arrow editor at the same time.


## Distributed Unique Resource Identifiers

Tracking resources (including scenes, macros, variables, character, and nodes) is a tricky process.
When you rename a variable that is already exposed with mustache placeholders in hundreds of text-heavy nodes,
Arrow should be able and does take the responsibility of updating all those placeholders.
Similar underlying actions are taken whenever you edit something in your projects.

Arrow needs to always know *identity* of each and any resource
regardless of the names we manually assign to them or where we put them.
For this reason, an immutable Unique Identifier (UID) is given to each resource on creation.
Arrow keeps these UIDs intact, never recycles them, and never reuses them for other resources.
When you edit a resource (e.g. updating a scene or node name)
Arrow looks up for the proper resource in the project document
using the resource's unique identifier.

> See also: [Project Data Structure][project-data-structure]

Historically these UIDs were generated by incrementing an integer seed kept in each document (i.e. `next_resource_seed` property).
This approach is fine for relatively small projects where only one author works on a single project file.
But the moment we try to divide a project to multiple files, or multiple authors try to merge their works, things get complicated.

In the old deprecated approach, when the first author in a team was creating a resource, his or her project seed would updated;
while the other authors' copies would not get the change until the documents where was merged.
If other authors had tried to edit their files at the same time, without the first authors changes,
they would get the same UIDs generated for the first author, due to using the old seed,
for their whole different resources, even if they were working on completely different scenes.

Another possible headache was dividing a project into multiple files.
UIDs in these files would also start from `0` up.
It meant you could not simply mix multiple documents to revise or to run,
or navigate between them without extra book-keeping efforts.

To solve these problems, our UID generation algorithm should somehow know who is editing a document at any time,
and if the document being edited is part of a collection and may mix into other documents at runtime.
In other words, Arrow editor should make sure its generated UIDs never collide in the scope of a multi-document project.

We didn't want to use a central authority for UID generation as well.

Thankfully, this is not a surprisingly new problem.
Many UID generation algorithms are designed to *distribute* right of UID generation
between multiple simultaneous producers.

One of the most fundamental changes in Arrow (*v2* and further) that touched almost everything else,
was migration towards new *Distributed UID* generation algorithms.

Two methods was implemented to allow Arrow users choose what fits their workflow more:

1. Snow (not generally recommended):

    This method is almost identical to the famous [Snowflake] algorithm; but with a project-specific epoch.
    To activate this method you should set `epoch` property of every project file,
    by editing the documents manually, to a certain shared unix-time in milliseconds.
    The producer or author may be switched from the editor (as explained further).

    > **Note!**
    > Unless you need to know the exact time in which each resource is created,
    > this method offers no special advantage over the recommended and default *Native* method (below).

2. Native (default):

    Default and recommended method is Arrow's own *Native* distributed UID generation algorithm.  
    
    > All parameters of this algorithm can be changed from *Authors* panel of the editor.
    > Click on the *Authors* button form Project tab of the Inspector to access the panel.
    
    From *Authors* panel, you can define multiple contributors
    and assign each of them a *unique author identifier* (AUID).
    Behind the scene, an *incremental seed* will be created and tracked for each author.
    These values will be mixed together with a *chapter ID*
    which can be unique to each document for projects divided into multiple ones.
    Chapter ID is chosen and set by you to the value you find proper.
    
    These parameters (chapter ID, author ID, and their respective incremental seed)
    are mixed to shape a 53-bit UID for each resource.
    In other words a number is created each time for each resource,
    by putting following bits together:
    
    + 10 bit chapter ID (0 - 1024)
    +  6 bit author ID (0 - 64)
    + 37 bit for more than 137 billion resources per author per chapter.

    These UIDs will be distributed, highly performant, minimal,
    and fit into a double-precision floating-point representation
    allowing easier implementation of Arrow runtime environments in languages with type limitations.

    For example, `7`th resource being created by the author `0` in chapter `0` gets `7` as its UID,
    `7`th resource by author `1` in the same chapter `0` gets `137438953479`,
    and `7`th resource by author `1` in another chapter `1` gets `8933531975687`.

    It becomes intuitive looking at the underlying bits in binary (base-2) system, where only two numbers `0` and `1` exist.  
    `0` in decimal equals `0` in binary and `1` is `1`; but `2` in decimal is `10` in binary,
    `3` is `11`, `4` is `100`, `5` is `101`, `6` is `110`, and `7` is `111`.  
    
    When we put numeral sections for each of above mentioned UIDs back to back (i.e. chapter-author-seed), we get:

    + **`0-0-7`** : `0000000000-000000-0000000000000000000000000000000000111` in binary = `7` in decimal
    + **`0-1-7`** : `0000000000-000001-0000000000000000000000000000000000111` in binary = `137438953479` in decimal
    + **`1-1-7`** : `0000000001-000001-0000000000000000000000000000000000111` in binary = `8933531975687` in decimal

    What about `3`rd resource by author `4` in chapter `5` ?  
    Bit sections **`5-4-3`** will be `0000000101-000100-0000000000000000000000000000000000011` in binary
    and give us `44530220924931` decimal UID.

> For normal workflows, Native algorithm (active by default) is a great choice and recommended.

You do not really need to care about how these things work under the hood.
You just need to know when and why some big numbers appear in your projects,
and why it is so important to set Author and Chapter ID values properly,
before starting to edit a project.

> Make sure to read [Chapters and Authors][chapters-&-authors] below.


## Managing a Large Workspace

### Naming & Categorizing Practices

We discussed Distributed Unique Resource Identifiers (or UIDs) above.
UID of each resource is reflected in its `name` property, by default, stringified as base-36.
Some resources may add affixes such as `scene_` or `var_` to the reflection as well.
These names are naturally unique, because they are made from totally unique UIDs.

Arrow editor's inspector panel allows users to rename any or all resources from their respective tabs.
Its main mind (core) takes care of renaming all the references to that resource (e.g. exposed `{variable}`s) afterwards.

Renamed or default, Arrow tries to keep these names unique
(unless you turn off the hardcoded setting before build, which is advised against).
This means if you renamed a resource to the UID reflection of a future resource
(going to be created from an unused seed), you could get a duplicate name.
Arrow tackles this problem with affixing the newly generated names
that are already used by the author, with underscores (`_`).

For example base-36 representation of the `10`th resource of the chapter `0` by author `0` is the letter `a`.
If you rename the `9`th resource there to `a` and then create a new resource (which is the `10`th so the expected `a`)
Arrow fixes the new resource's name to `a_`.

Arrow names are case-sensitive. In other words, resource `a` is different and independent from resource `A`.
This means we could use `A` for our renamed 9th resource in the example above, and get a normal `a` for the 10th.

With this knowledge of underlying functions,
let's discuss conventions and good practices you may find useful:

**Only Rename What You Need**

In a grown large project, will be virtually endless number of resources (scenes, nodes, etc.).
You are the decision-maker. You decide which resources should be renamed to more human-friendly titles.
One good practice is to only rename nodes that really need to be found easily and quickly, such as focal nodes.
Many nodes that are small gears in big branches may be left to have their own machine-made names.
You can always use alternative ways (mentioned below) to categorize and easily locate your nameless nodes.
On the other hand, giving every Scene, Character or Variable its own meaningful name would make more sense.

**Rename for Meaning and Scope**

Some resources including scenes, macros, variables and characters are filterable by their name.
Naming these resources meaningfully, optionally namespaced or scoped, and idiomatic,
allows you to easily filter and find them in their possibly large lists.

For example, if you name-space all your love scenes with `love-{major-event}-{minor-event}`
(e.g. `love-triangle-duel`, `love-triangle-first-encounter`)
not only you can filter and recognize them later among many other scenes,
but you will have them listed together when the list is sorted alphabetically.

Your resources would also look much more meaningful when used, viewed on grid, and exposed
(e.g. `{Hero.alias}` vs `{char_x1y2.a}`).

**Prioritize Categorizing**

Resource names may reflect more information about their kind, purpose and category.
A node may be named `love-in-first-sight-01`; but there are many other (more beautiful) ways to do so as well. 

Node (developer) notes are very handy.
You can put unlimited number of category badges or subject tags
(with any format you prefer such as `[battle-scene, love-affair, duel]`)
in node notes and query them using global text search (from the status bar).

Also consider using [Character]-Tags to create relations whenever proper.

**Have a Consistent Case Convention for Resource Names in Your Workspace**

Having a special case when naming nodes,
such as `snake_case`, `Title Case`, `CamelCase`, `kebab-case`, etc.
offers many advantages.

Things stay tidy and you can recognize them in a blink,
specially if you use different cases for different purposes
(e.g. `CamelCase` for characters, `kebab-case` for tags and `snake_case` for variables).

You almost never collied with default node names
because our base-36 representation does not include
dash, space, underscore, or uppercase characters used in many cases.
Fore example, the name `heyday` is representation of the UID `1053043162`,
but you never get it as `Heyday`, `hey-day` or `hey_day` from Arrow.

Note also that none of mentioned cases is preferred by Arrow.
Even though Arrow replaces restricted characters in some names, by default with underscore (`_`),
to keep them easier and safer to expose, any other allowed character including dash (`-`)
would be perfectly safe as well. This is your personal, team, or project convention to be made and maintained.

### Scenes & Macros

Scenes are the first front, when it comes to project organization.

Arrow projects can have unlimited number of scenes.
The only restriction is your device's physical memory and storage.
When you open a project file, Arrow loads all its data into the device's memory.
It may create few copies of it there too, for edition history, snapshots, etc.
Yet because modern devices can handle enough of them,
you most-likely need to only care about the creative side of you scenes in each document.

> To create new scenes and/or open them to edit, head to Scenes tab of the *Inspector* panel.

One very good practice is to follow the same conventions
that novelists and screenwriters have been using for decades.
These authors, organize their dramatic works to multiple chapters/episodes
and each chapter to multiple scenes. This is supported and recommended by Arrow.

We can divide our project (work directory) to multiple chapters (`.arrow` documents)
and each chapter to as many scenes as we find right.
Major events can happen in chapters/files, and minors in scenes,
or any other division that fits needs of your project.
You can even divide your project to one chapter/document per character, place, etc. depending on your creation.

The main point is to divide, because projects can grow really fast in number of nodes.

> Make sure to read [Chapters and Authors][chapters-&-authors] for more details.

Using Macros is another way to manage divisions. They are scenes with a twist: a double identity!
In nature, they are identical to other scenes and actually the same resource type with an optional `macro` property set to `true`;
but they enjoy special editor, console and runtime treatments.

You can either play them inside [Macro-Use] nodes, or [Jump] into one of their nodes and make them play like normal scenes.
The difference is that in the first contained use (exclusive to macros),
observing an EOL (i.e. End-of-Line) is interpreted as if we should continue the parent/container scene forward,
contrary to the normal scenes and macros jumped into, that EOL stops execution of the branch and most-likely the game.

Macros are designed to be created and used as
repeatable computational units, reusable blocks, or functions;
otherwise they offer no practical advantage over scenes.

One common usage is in state management with relatively complex logic.
For example you can create a macro to update multiple variables (stamina, skill, health) with different factors,
each time your hero fights a boss, based on other variables (boss_strength and battle_outcome).
You can then re-use this macro in each battle scene/branch. You avoid copy-pasting,
and when you intend to change all your scoring events, you only need editing one building block of your project.

> For more information on how macros are handled, check out: [Macro-Use]

### Chapters and Authors

New project documents (i.e. `.arrow` files) are created from a template (blank project),
including a basic scene with an [Entry] connected to a minimal Hello-World [Content] node.

This untitled project has few very important properties,
the first things you should take care of:

+ Chapter-ID of this document that is set to `0` by default
+ Its active author that is called `Anonymous Contributor` and has Author-ID of `0` by default

These properties affect all the UIDs created in this file (including the existing pre-set ones),
and in long term, affect inter-document relationships of your project being divided to multiple files.

It is very important to set them properly before getting started.

Following is the standard or suggested procedure,
specially recommended when you intend to divide your work to multiple chapters/files:

**Large Project Document Creation**

Try to use a clean work-directory to have a fresh `.arrow.project` for every independent large project.

Follow these steps, each time you create a new document:

+ Save it first
+ Open *Authors* panel (from Project tab of the *Inspector* panel)
+ Set a unique `Chapter`-ID **and press update**
    > Value and order is optional, but you are better avoid re-using them,
    > even temporarily, to avoid UID collision.
+ Add authors that would work on this project (per directory or by file) and assign each a unique `AUID`
    > It is possible and easy to add new authors over time but removing them would be more tricky.
+ Make sure the right author is active (that is you editing this chapter on this device)
+ Close the panel
+ Create a new scene, set its entry as the project's active entry
+ Remove the old initially created scene

You are fine to continue.

Following steps above, would guarantee that you never get the same UID throughout different documents of the same project.

> **Quick Tip!**  
> A good precaution is to reserve chapter `0` and/or author `0` for your [shared resources][sharing-resources].  
> Continue reading for further information.

Remember also that you can always change `Chapter`-ID, or any contributor's `AUID`,
but changing these values will only affect the UIDs to be generated next, and never those already there.
This feature allows many useful hacks including the ones for [Sharing Resources][sharing-resources],
and is the reason why you are better removing new project's pre-set nodes first.

> Authors' extra `info` has no effect on UID generation,
> that is just for you to share information with the world if you want to!

UID collision may not seem to be a big deal at first.
Sure, it can be tackled with some runtime hacks and/or extra book-keeping;
but we better be safe than sorry, specially in complex workflows,
full of contribution complexities, and technical complications ahead.

### Sharing Resources

Arrow takes each project file as a fully isolated and independent narrative.
In other words, there is no support for workspace state-sharing, inter-document linking, etc., neither such features are planned.
The good news is that a big part of what we would need is already there.

Thanks to collision-free distributed UIDs, you can always mix multiple documents at runtime,
and create your way around limitations by using a custom node, or even a [Marker] hook
(e.g. to jump between different documents).
Yet few tricky points remain to be taken care of.

One issue is sharing and syncing globals (e.g. variables and character-tags) in runtime.

To tackle this your runtime code may handle resource updates
(variables or character-tags) using their names (not their UIDs).
This is probably the easiest way to go with the least technical complications.
In this case any time a scene is loaded at runtime,
all its variables or characters that are not already initialized,
will be created in memory with values or tags equal to their initial state defined in the scene.
If they are already initialized, their state would not be reset.
This approach is really easy to implement and controllable from the editor (no need for data hacks);
but a simple typo in a shared resource name, could make a mess in play-time,
so you need to be extra cautious in that regard.

Another way is to have runtime handle resource updates normally with their UIDs.
We just need to make sure that a resource has the same exact UID when used in another file.
A tidy and clean way is to have a file or section (e.g. chapter `0` and/or author `0`) as the `base` or root.
All global resources to be shared, are created first in this base and get a UID.
We can then merge these resource blocks into other files, using a diff-merge tool, manual edit,
or cross-chapter resource transfer's *reuse* mode (read below).
Because the base UIDs are not going to ever be creating in higher level chapters,
we would expect no other resource overwriting them, and are fine handling them with their UIDs.
This approach is pretty much name independent, and allows share and merge any resource type (including macros)
but you need to process exposures using local resource names, and make sure they are not re-initialized unless desired.

### Cross-Chapter Resource Transfer

Arrow editor versions higher than `2.0.0` also support (experimental) resource merger.
You can use `Ctrl + Shift + C` to pick up selected nodes from the grid.
All the data needed for the merger including all the referenced resources (variables, characters, etc.)
will be packed as well, into a JSON string that will be pushed into your device clipboard.
You can paste this chuck again to any other chapter's scene grid using `Ctrl + Shift + V`.  
You can also transfer a whole scene/macro, a character or a variable using the same shortcuts,
while focusing on the respective lists in the inspector panel.  

When pasting, depending on the underlying circumstances, you may have one or some of following
merger modes available:

+ **Reuse**

    This method keeps the source UIDs for all the resources imported to the destination, *unless the UID is already taken*.
    In latter case, if the resource is variable or character and the inner types are similar,
    the destination resource will be used/referenced by the importing data and the transferred source will be ignored.
    Remainder of resources (including nodes, scenes and macros) get new UIDs from the destination chapter.
    
    > This strategy is designed to share variables and characters, between chapters (instead of using a merger tool).
    > It *does not update* the already shared resources, and is available only if the source and destination documents have *different chapter-IDs*.

+ **Recreate**

    It is more like a full duplication. While preserving all the relations from the source,
    all the importing resources will be assigned new UIDs from the destination, even if their source UID is not taken.

By default, imported data will be renamed (affixed), if their name is already used for another resource.

In both strategies, if resources are pasted as a whole (into an inspector list),
their hosting scenes (if any) will be recreated. Pasting on the grid is different though;
the selected nodes will be moved to the destination grid,
and empty scenes (those having only their entry and not referenced) will be dropped.



<!-- References -->
<!-- internal -->
[sharing-resources]: #sharing-resources
[chapters-&-authors]: #chapters-and-authors
<!-- relative -->
[Jump]: ./jump
[Variables]: ./variables-and-logic
[Characters]: ./characters
[Dialog]: ./dialog
[User-Input]: ./user
[Monolog]: ./monolog
[Content]: ./content
[CLI]: ./cli-arguments
[project-data-structure]: ./project-data-structure
[Character]: ./characters
[Macro-Use]: ./macro-use
[Entry]: ./entry
[Marker]: ./marker
[Variable-Update]: ./variable-update
<!-- absolute -->
[web-app]: https://mhgolkar.github.io/Arrow/
[Snowflake]: https://en.wikipedia.org/wiki/Snowflake_ID
