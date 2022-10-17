We use recursive proofs to handle search requests on state which is distributed across the cluster.

# State

The state is a merkle tree of `n` bundles, which are merkle trees of messages and the block in which those messages were sent:

                      state                
                        |
     _______________________________ ...
    |           |           |
  bundle      bundle      bundle
    |           |           |
   ...         ...          |
                         _______
                        |       |
                      block    root
                                |
                             _______
                            |       |
                           ...      |
                                 _______
                                |       |
                               ...     ...
                                |
                             message
                                |
                         _______________
                        |       |       |
                    address  content signature

# Substring Search

## Definition

A substring search has inputs:
    - Block range
        - Start
        - End
    - Match string
    - n (return the nth match)

It outputs the nth message where the match string is a substring of the message content.

## Recursive Proof

### Structure

Suppose we are looking for a message in blocks 0-7 with a substring "x".
We end up with a recursive proof tree like this containing 3 types of proofs.


                K of Set is Nth of Search
                            |
                            |_______________________________
                            |                               |
                           0-7                            K of Set
                            |
                     _______________
                    |               |
Switcher           0-3             4-7
                    |               |
                 _______         _______
                |       |       |       |
               ...     2-3     ...     ...
                        |
                     _______
                    |       |
Matching Set       ...      3

### Matching Set

Matching Set accepts a match string and a bundle merkle root as inputs.
It outputs the number of matches, and a merkle root of the matches.

It doesn't output the matches directly because we only force servers to make fixed length responses to avoid griefing.
When we force a bundle search on chain we recieve a proof and a signature over the merkle root and outputs.
We can then force the server to reveal each element in the merkle tree independently. (TODO: this requires additional forcemove infrastructure)
TODO: what happens if nothing matches?

### Switcher

Switcher first verifies two Switcher or Matching set proofs.
Then it verifies that the blocks referred to in the child proofs refer to disjoint and contiguous regions in order.
Then it takes an index k, which refers to the combined region, and figures out which of the regions that refers to (if any).
Then it outputs the boundaries of the combined region, the index in the subregion, and the merkle root of the subregion.

The purpose is to take an index over the whole set of search results, and prove the specific set of search results it refers to.
TODO: what happens if the switcher gets nothing from its children?

### K of Set

Takes an index k and a hash defining a set (possibly a linear hash, possibly a merkle hash) and outputs the kth element of that set, if it exists. (TODO: what actually happens if it doesn't exist, is there an attack vector here?)

### K of Set is Nth of Search

This is the top level proof.
If there is something to be found:
    It verifies a Switcher that runs a search starting at the the start block, and ending before or at the end block.
    It takes the set and index from the switcher and verifies that those values are identicial to the ones passed into a K of Set proof.
    It verifiers the K of Set proof.
    It outputs the result of the K of Set proof.
If there is nothing to be found:
    It shows that a switcher over the block range returns nothing.