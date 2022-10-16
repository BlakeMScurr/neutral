# Neutral

Neutral is a suite of tools for building traditional web applications on a credibly neutral highly scalable distributed backend.

Existing servers are centralised and can arbitrarily withhold service, give false responses, or drop your data.<br/>
Blockchains, on the other hand are credibly neutral but they suffer from scalability problems, especially for data (as opposed to computation).<br/>
Neutral clusters are a middleground with almost as much scalability as traditional servers, and almost as much credible neutrality of blockchains.<br/>

Neutral clusters can be joined by anyone willing to put money at stake on Ethereum and run a server. 
Recursive ZKPs guarantee correct responses across the cluster.
State channels guarantee liveliness and permit arbitrary best case data scaling.

# NeutralChat

NeutralChat is social media for Ethereum on top of a neutral cluster.<br/>
NeutralChat is the first demonstration of a neutral cluster.<br/>
NeutralChat guarantees that anyone can cheaply make a post, and that every post can be found by anyone.<br/>

## Technical Details

### Guarantees

Anyone force servers in the cluster to respond to its requests, slashing them if they don't respond promptly.<br/>
All servers must respond to `search` requests. To do so, the server must respond with the relevant posts and a proof that they are correct.<br/>
A leader is selected every `interval` blocks who must handle `post` requests.<br/>
To address a `post` request, the leader must store the data and distribute it to the appropriate server.<br/>
The leader is forced to post a state root on chain at least every `interval` blocks.<br/>

### Queue

To force a server to repspond, open a payment channel with them, make a request and put it in the queue by spending from the channel.<br/>
A server must respond onchain within the `response_window`, or their entire bond will be slashed.<br/>
It costs a server to respond onchain, so they're incentivised to respond offchain.<br/>
Enqueue and dequeue should cost around the same gas to minimize griefing attacks by the client, or censorship by a server.<br/>
In order to enqueue, the request must be dated after the current time.<br/>
In order to dequeue, the response must include a signature of the response body and the request body.<br/>

### Recursive Composition

A search request specifies a time range to which it applies.
The bundles of messages are distributed across various servers, so they have to be requested to form a search respone.
The range determines which bundles need to be searched, and therefore which servers should have sub requests made to them.
The responder makes sub requests to all the relevant servers, where the request range specifies one bundle.
The range determines the response leeway, as recursive proofs need at least 2 times longer than non recursive proofs, in order to recieve the sub responses.
If a sub response fails and the sub server is slashed, the responder shouldn't necessarily be slashed. So there should be an extra leeway period to allow the responder to ask all other servers holding that bundle.
A recursive proof can specify unavailable bundles, and if the responder can prove that all servers holding that bundle are slashed, then the responder can't be slashed for excluding that bundle.
Ideally we can recover any bundle, so the "slashed bundle" defence is removed if a new server comes online with the bundle. But there is a grace period where the defence holds, so there is no race condition where the responder didn't know that a new server had the bundle.
Smaller ranges are cheaper.

### Bond

Servers are Ethereum nodes using a restaking network.
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
 - An `exact_match` search request with a state root from after `storage_leeway + request_date`<br/>
 - Where the search `query` exactly matches the post response's content<br/>

### State Update

The server must continuously update the onchain state root every `update_period`.<br/>
The bond is slashed if it fails to do this.<br/>
In addition to a new hash, it must provide a ZKP showing that the data is in order, and that the new state is a superset of the old state.

### State Structure

The each bundle is made of slots of fixed size containing a message.
Each message has an ethereum address, a block_number at which it was stored, a `content_length` byte body, and a signature.
The messages are stored in order.
The bundle root is the merkle root of all the messages.
The state root is the merkle root of all the bundles.

### Joining the Cluster

Anyone can join the cluster by restaking their Eth.
The next leader is just the next server in the list.
The leader must be known ahead of time, so servers can only leave the list if they're `exit_period` `interval`s from leadership.
Similarly, servers can't be the leader soon after they join.
The leader passes on leadership as they update the state root.
There is a leaving penalty, both to avoid jockeying, and to penalise making data less available. The penalty is proportional to the rarity and amount of the data.

### Distribution

There is a record of who holds which bundles.
The leader always has to hold the bundle they build.
Any server can declare that they hold any bundle.
Anyone can forcibly open a channel to download any bundle, the channel costing a small fixed fee.

### Search

There are several types of search, each with a different use case and different cost to the server:
    `exact_match`, `next`, `previous`, `content_substring`
`exact_match` returns a 1 or a 0 depending whether the a message (including metadata) is in the sorted list.
`next` gives the first message stored after a given point in the sorted list.
`previous` gives the first message stored after a given point in the sorted list.
`content_substring` gives the nth message whose body matches a given string.

### Impersonation Fraud

If there is any `exact_match` response where the message has an invalid signature, the server's bond is slashed.

### Monetisation

Opening a state channel (as a client) incurs a protocol fee, which will be off in "startup mode" and "hyperstructure" mode, and on in an intermediary "extraction" period.