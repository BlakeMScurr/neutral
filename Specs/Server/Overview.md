# NeutralChat 1.0

NeutralChat 1.0 is social media for Ethereum run on a neutral server.<br/>
NeutralChat guarantees that anyone can cheaply post, and that every post can be found by anyone.<br/>
It proves the basic technology required for data constrained neutral applications.<br/>

The server is run by the Neutral team.
ZKPs ensure correct responses.
State channels guarantee liveliness and permit arbitrary best case data scaling.

## Technical Details

### Guarantees

Anyone can force the server to respond to their requests, slashing them if they don't respond promptly.<br/>
The server must respond to `search` requests with the relevant posts and a proof that they are correct.<br/>
To address a `post` request, the server must store the data.<br/>
The server is forced to post a state root on chain at least every `interval` blocks.<br/>

### Queue

To force a server to repspond, make a request and put it in the queue.<br/>
A server must respond onchain within the `response_window`, or their entire bond will be slashed.<br/>
It costs a server to respond onchain, so they're incentivised to respond offchain.<br/>
Enqueue and dequeue should cost around the same gas to minimize griefing attacks by the client, or censorship by a server.<br/>
In order to enqueue, the request must be dated after the current time.<br/>
In order to dequeue, the response must include a signature of the response body and the request body.<br/>

### Bond

The server holds some Eth as a bond.
Their stake can be slashed by a fraud proof (search fraud, storage fraud, lateness, impersonation, or state update failure).<br/>
If the bond is slashed by a fraud proof, we call the fraud proof provider a fisherman, and they recieve a reward.<br/>
The fisherman's reward must be small (say, 2% of the slash) to prevent the server operators from slashing themselves to circumvent vesting.<br/>

### Search Fraud

The queue itself does not check the validity of the request or response bodies.<br/>
For search requests, there is a separate contract that identifies fraudulent search responses.<br/>
Anyone who can demonstrate that the server committed search fraud can slash the bond and recieve a fisherman's reward.<br/>
To prove a search fraud the fisherman must:<br/>
 - Show a valid search request where the state root is an actual onchain state root<br/>
 - Show that is a signed response from the server.<br/>
 - Show that the response body is invalid.<br/>
     - A valid response (body) is a valid ZKP proving that the `query` on the `state` gives `result`<br/>

### Storage Fraud

A post response is just a signed request, therefore the queue implicitly validates the response at dequeue.<br/>
A post response means that the server will store the request within `storage_leeway` blocks of `request_date`.<br/>
Storage fraud is when the server doesn't store a post it said it would within the time period.<br/>
Anyone who can demonstrate storage fraud can slash the bond and receieve a fisherman's reward.<br/>
To demononstrate storage fraud, you must provide:<br/>
 - A post response<br/>
 - An `in_bundle` search request with a state root from after `storage_leeway + request_date`<br/>
 - Where the search `query` exactly matches the post response's content<br/>

### State Update

The server must continuously update the onchain state root every `update_period`.<br/>
The bond is slashed if it fails to do this.<br/>
In addition to a new hash, it must provide a ZKP showing that the data is in order, and that the new state is a superset of the old state.

### State Structure

Each bundle is made of slots of fixed size containing a message.
Each message has an ethereum address, a block_number at which it was stored, a `content_length` byte body, and a signature.
The messages are stored in order.
The bundle root is the merkle root of all the messages.
The state root is the merkle root of all the bundles.

### Search

Interally we require `in_bundle` to prove that a bundle has a message that it should and verify its signature.
Externally we require various kinds of search to meet UI needs, namely `content_substring` and `by_user`.
This enables a low cost forced path since 1 proof is posted and verified on chain.

### Impersonation Fraud

If there is any `in_bundle` response where the message has an invalid signature, the server's bond is slashed.
Note that there are two types of `in_bundle` request, one that takes a hash to save onchain data costs, and another that takes the whole message so that the signature validity can be checked on chain.

# Design Principles

Minimise forcing costs.
Minimise marginal forcing costs.
Fishing can be expensive.
Forcing cost is dominated by onchain costs.
Trade onchain data availability for computation.

## Minimise Forcing Costs

To meaningfully defeat censorship, a user should practically be able to use the service even while every server is willing to spend money to censor them.
Concretely this means designing the system to minimise the cost of forcing it to respond to your requests.
We aim to give freedom of speech to a hated minority of 1.
Note, we still assume that the L1 remains accessible.
Note, erasure coding based systems tend to require substantial coordination to recover data.

## Minimise Marginal Forcing Costs

Even if amortised forcing costs are minimised, they may be high enough that a server can ignore a request and call the user's bluff.
So we may want to incur a small penalty in overall costs to split it into multiple parts, so that a user can demonstrate their seriousness.
<!-- TODO: actually study the game theory. I.e., perhaps the server can more easily ignore small threats, even if they're more likely to be followed through on. -->

## Fishing can be Expensive

The exception to minimising onchain costs is fishing.
When the server gives an invalid result they may lose their stake, some of which goes to the user as a "fisherman's reward."
We can offload expensive onchain computations to the fishing step, since the reward should easily cover the gas costs.

## Forcing Cost is Dominated by Onchain Costs

Onchain costs are inherently expensive as they impose a computational across a very large set of nodes.
Each step along the forced path only imposes a cost on a single server, even though that may be high.
This is just a rule of thumb - the two can be traded off once the concrete costs are known.

## Trade Onchain Data Availability for Computation

Rollup technology appears to have better asymtotics than sharding.
Even if linear data scaling is possible in principle, its security properties at L1 appear more tenuous than existing plans for computation scaling.
Therefore we should assume that onchain computation will get cheaper at a faster rate than onchain data, and we should plan around that.