
Arrow is developed using free and open-source [Godot Engine](https://godotengine.org/).

Godot's official documentation has a comprehensive guide on
[how to export Godot projects][godot-export-instruction] 
which is a pretty easy and straightforward task.

Although we support or release for a selected bunch of platforms,
Arrow is generally expected to work fine on all the desktop platforms and architectures supported by Godot.

> Arrow v3.x (current generation) works on top of Godot v4.x.
> We try to keep up with the most recent stable release of Godot, but it is not guaranteed.
> To be safe, you can use the same engine version of Godot that we have used for our most recent [releases].


## Rolling Release?!

Exporting project as mentioned above may be the standard way,
but if you want to take advantage of Godot's flexibility, modify the editor,
or use the most recent features hot from the oven, there is an alternative way to enjoy the bleeding edge!

Godot game engine, which is used to develop Arrow, has a very interesting feature:
If you copy the right version of Godot Engine (editor executable file)
in the root of a game project (here Arrow), and run it,
you'll get the game running instead of the editor
as if it was exported with debug mode.

So if you want the latest features,
whether you want to change any part of Arrow or not,
running it directly from cloned source can make things move quicker:

+ Get Arrow from the git repository
+ Download (and extract) the right Godot Engine executable
+ Copy the executable into the root of the cloned Arrow project (where `project.godot` file is)
+ Optionally rename the Godot executable (to `Arrow`, `Arrow.exe`, etc. depending on your OS)
+ Run the executable and enjoy
+ You can `.gitignore` the executable and other artifacts created on the fly, so you can easily pull new commits
+ Pull new commits to update your editor any time you found a new feature interesting

> Although we try to keep the main branch fairly stable (near beta or release candidate),
> there is never a guarantee that things wouldn't go wrong,
> so take necessary precautions, in other words
> remember to backup your works!


## Additional Notes

+ Arrow's hardcoded default settings are in `./scripts/settings.gd` file, you can change them if you need.
  > Some modules and nodes have their own settings as constants in their respective scripts.
  > These are *not recommended* to be altered in general.

+ The official browser-based (HTML-JS) runtime's source is bundled with Arrow in `./runtimes` directory.
The template `html-js.arrow-runtime` file is what Arrow uses to create playable exports.
If that file is removed, Arrow editor will rebuild it from its source,
which can be make modification of the exports easier.



<!-- References -->
[godot-export-instruction]: https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
[releases]: https://github.com/mhgolkar/Arrow/releases
