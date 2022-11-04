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

# Bundle Level Proofs

Bundle level proofs apply to single bundles, and can be produced by a single server who holds that bundle.
They are useful for verifying the integrity of a message or bundle, and for composing into proofs that operate across the whole state.

## In Bundle

`In_Bundle` proofs prove that a given message is in a given bundle.
They accept the message hash and the bundle merkle root as public inputs.
Inside the circuit they verify a merkle proof showing the message is in the bundle.

The storer sends an `In_Bundle` proof to the user as the final step in storing a message.
After that, the user can be certain the message is stored and delete their local copy of the message and any metadata.

`In_Bundle` can be be altered to take the message as public input rather than its hash. It computes the hash in the circuit and proceeds as normal.
This is used when proving that their is an improperly signed message in the store. It saves onchain computation (namely hashing the message) by putting it into the circuit.

## Matchers

Bundle level Matchers find all the messages in a given block that match some criteria.
They are a crucial building block for whole state search proofs.

The public inputs are the merkle root of a bundle, and a search criteria (which depends on the particular kind of matching proof).
The (public) output is the number of matching messages and a merkle hash of them.
We output the merkle root to reduce onchain communication complexity in the forced path.

<!-- 

What is going on here?
We have a rather troubling issue, namely, how are we supposed to get search results such that:
    - Forcing a single result is cheap on chain (one small proof, the public inputs, and the result)
    - The server return the next page of results at small marginal cost (one proof and one request per bundle holder)
    - We can trade off forcing cost for throughput

What is my rough idea of what happens here?

I think we should conceptualise the state machine for the state channel as a ring as the happy path, where we essentially just post to chain.
Spikes from the ring are states where the channel is closed in the one party's favour if they detect problems from the other party.

The compliant forced path is:
    - User posts query
    - Server posts proof, result merkle hash, and result length
    - Repeat
        - User requests n nodes
        - Server sends n nodes

The non-compliant offshoots are:
    - If the server doesn't respond it is slashed and the user is rewarded
    - If any collection of committed nodes don't hash to the merkle hash, the server is slashed and user rewarded

OK, so what should the hash be? We have a few options, pedersen, poseidon, rescue, sinsemilla, sha3.

OK, what are my requirements for my hashes?
    - SNARK friendly
    - Production ready implementations in both Solidity and Halo2

Poseidon: https://github.com/privacy-scaling-explorations/poseidon, (https://github.com/ChihChengLiang/poseidon-tornado, https://github.com/appliedzkp/maci/blob/36387984f15a448152f5bb4227db978c75082e59/contracts/ts/buildPoseidon.ts)
Pedersen: _, ?
Sinsemilla: https://github.com/ZcashFoundation/orchard/tree/main/src/primitives/sinsemilla, ?
Rescue: 
Sha3: 


 -->

### Match at Offset

### Substring Match

# Aggregation

## Happy Path Costs

# Indexing

## Multi Indexed Costs

<!-- # Substring Search

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
Index Subset       0-3             4-7
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

### Index Subset

Index Subset first verifies two Index Subset or Matching Set proofs.
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


# In Bundle

In Bundle is a proof that accepts a bundle hash and message hash as public inputs.
There is another version that takes the whole message (sender, content, and signature) so that we can check signature validity.
It verifies that there exists some index between 0 and the bundle's `max_capacity`, such that
there is a merkle proof that the message is in the bundle.

Note, this may not be needed in recursive proofs, so we can potentially use Groth16 or Plonk instead of Halo2 if the concrete verification cost is too high. -->

