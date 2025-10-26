
Here is a list of Arrow editor's keyboard and mouse shortcuts:


## Inspector Panel

To open a node in the *Inspector* panel, simply `Double-Click` on any Node,
or just select one if *Auto Inspection* quick preference is active.

+ `Ctrl + I` toggles the *Auto Inspection*.

You can also use status-bar's *Quick Pref.* menu button to manage similar behaviors.

Other useful shortcuts related to the Inspector panel are as follows:

+ `Ctrl + Shift + Minus (-)` resets Parameters to the last saved state of the inspected node
+ `Ctrl + Shift + Plus (+)` updates the node parameters
+ `Ctrl + P` toggles the Inspector panel
+ `Ctrl + \` changes the Grid view to focus on the inspected node

+ `Ctrl + U` toggles *Auto Node Update*

*Auto Node Update* quick preference (enabled by default) applies node modifications automatically *when user leaves the node*.
That is by inspecting another node or deselects the current one by clicking on the grid or multiple selection.

> This behavior only works with nodes. Other resources must be set to update manually.
> To store data permanently, you should save the document.

Re-selecting a node will *reset* modified parameters to the latest kept state if the *Reset on Re-inspection* quick preference is enabled.

### Item Lists

Item lists which offer move or sort functions (e.g. *Dialog* and *Interaction* lists),
would also support following shortcuts:

+ `Home` moves selected items to the top
+ `End` moves selected items to the end
+ `PageUp` or `Ctrl + Up` moves selected items up
+ `PageDown` or `Ctrl + Down` moves selected items down
+ `Delete` removes selected items if allowed


## Grid (Graph) & Editor

+ `Ctrl + Arrow-Keys` moves selected nodes on the (focused) grid

+ Selection
  + `Ctrl + W` deselects nodes all
  + `Ctrl + Left-Click` is used to select multiple nodes
  + `Shift + Left-Click` selects a branch (i.e. a series) between two selected nodes
      > It accept one beginning and multiple end nodes.
      > You can activate waterfall mode holding `Alt`, to select sibling nodes of the series as well.

+ Query (Global Text Search)
  + `Ctrl + Q` or `F3` focuses on the query (search) input
  + `Ctrl + 2` locates the next match on the grid
  + `Ctrl + 1` locates the previous match

+ View
  + `F11` toggles full-screen
  + `Mouse-Wheel` zooms in or out, so does `Ctrl + Plus|Minus`
  + `Middle-Mouse-Button` grabs the grid and moves the view
  + `Ctrl + Mouse-Wheel` scrolls the grid vertically, and horizontally if combined with `Shift`
  + `Ctrl + 0` resets zoom


## Console Panel

Following shortcuts are to launch the *Console* panel and play from a special node forward:

+ `F4` plays form the *project's* active entry after clearing the console
+ `F5` plays from the *scene's* active entry after clearing the console
+ `F6` opens the console with the state in which it was closed
+ `F7` plays the last selected node (if any) without clearing the console


## Project Management

+ `Ctrl + S` saves the open document
+ `Ctrl + E` quickly re-exports using path and format of the latest export if any


## Revision/History Management

+ `Ctrl + D` takes a snapshot
+ `Ctrl + Z` dows undo the last applied update
+ `Ctrl + Shift + Z` does redo the last applied update

> History behavior, still being an unpolished feature, is not active by default.
> To have it enabled, increase history size from the *Preferences* panel.
