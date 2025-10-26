
*Sequencer* nodes are designed to run multiple outgoing slots (branches)
in parallel or queued.

**Handle with Extensive Care!**  
Sequencer behavior depends heavily on runtime code and is *potentially unsafe*.
Check [Use] part of this document for more information.

### Conventions:

+ Skipped Sequencer nodes run their last connected slot and short-circuit.  
If no slot is connected, it is EOL.

+ Sequencer is an automatic node: it does not wait for user interaction.

+ Considering their natural purpose, Sequencer nodes expect at least two outgoing slots.

+ Sequencer *requests* to play all of its connected slots one by one in order (from index `0`).
How those requests are handled and the real order of nodes being played depends on runtime code.
*No guarantee is expected by convention*. Check [Use] part of this document for more information.

### Use:

Although Sequencer nodes request to play their connected branches in outgoing slots order,
they may actually run queued or in parallel (with no expected guarantee), depending on runtime implementations.

They also do not care if the nodes in a branch being played,
are automatic or not, they just fire/request them to be run.

Branches themselves could have Sequencers too,
end up running in exponentially unexpected order.

It may cause many different unintended behaviors, such as
variable checks and updates in wrong order,
displaying multiple nodes waiting for user action on the wall,
printing contents in surprising ways,
etc.

Sequencer is not responsible for sensibility of the result.
The responsibility is all on your shoulders!

An unsafe example is to sequence a branch modifying a [Variable]
and another branch updating or conditionally depending on the same variable.
If these branches run fully synchronous and queued, we can safely assume that
the first branch updates the variable, then the second branch runs.
But in case they are played in parallel by runtime (e.g. through multi-threading
or some kind of channel with no guaranteed message order), we can never be sure.

Yet many relatively safe operations are possible using Sequencer nodes.

One example is to manipulate multiple variables, even in parallel,
thorough operations that are not dependent on one another.
A manual node could tail the sequence as well,
to make sure all operations are done
over the time we are waiting for the user action.

Another possibility is to design runtime so it actually
expects multiple content being displayed at the same time,
and queue them if needed.
For example a runtime can support scenes where multiple characters are present.
Each one would say something if a certain criterion is met.
In that case a Sequence of branches requested in order, may be processed in parallel,
check some [Variable]s and if the [Condition]s are right, play some [Dialog]s
that will be added to the display queue by the runtime to be played with proper timing.

### See also:

+ [Navigation and Plot Management][navigation]
+ [Randomizer] & [Hub]



<!-- internal -->
[Use]: #use
<!-- relative -->
[navigation]: ./navigation-and-plot-management
[Variable]: ./variables-and-logic
[Condition]: ./condition
[Dialog]: ./dialog
[Randomizer]: ./randomizer
[Hub]: ./hub
