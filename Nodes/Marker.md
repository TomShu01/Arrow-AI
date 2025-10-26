
*Marker* nodes are designed to provide general-purpose visual labels,
both on the editor's grid and the console.

They have a simple text `label` and a `color` making them distinctly visible
on the grid and its mini-map(s).

### Conventions:

+ Marker is an automatic node: it does not wait for user interaction.

+ Whether skipped or not, Marker nodes always play their only outgoing slot;
but they may or may not show up to players if skipped, depending on the runtime.

### Use:

Marker nodes are good means of annotation.

You can use them to mark places in need of later attention,
labeled as `WIP` (i.e. work in progress), `TODO`, `NOTE`, etc.
with distinctive (conventional) colors.  
Yo can also add extra developer *node notes* to them,
sharing your thoughts or tracking tasks to be done.

> Node notes will be purged on many export formats but are kept in saved projects.

How our little Marker friends are used and their behavior,
highly depends on the developers workflow, and how they are implemented in runtime code.

Arrow's console and the [official HTML-JS runtime][runtime-html-js]
(which are mainly designed to be play-test, review and debug tools)
tend to display active markers to their players.

> You can skip any Marker to avoid displaying them on play-time,
> if they are only needed for annotation on the grid.

A custom workflow (and runtime) may decide to use markers to signal events.
These events may be captured and handled by runtime hooks.
Marker's `label` parameter may as well be used to define
which function shall be called and/or what arguments should be passed.
It is a quick and dirty way to prototype and extend Arrow
without spending time to create beautiful custom node types.

### See also:

+ [Frame]
    > For grouping nodes on the grid.



<!-- relative -->
[Frame]: ./frame
<!-- absolute -->
[runtime-html-js]: https://github.com/mhgolkar/Arrow/tree/main/runtimes/html-js
