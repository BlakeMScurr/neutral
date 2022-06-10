# Neutral

Neutral is a suite of tools for building credibly neutral servers.

Existing servers are centralised and can arbitrarily withhold service, give false responses, or drop your data.<br/>
Blockchains, on the other hand are credibly neutral but they suffer from scalability problems, especially for data (as opposed to computation).<br/>
Neutral servers are a middleground with almost as much scalability as traditional servers, and some of the credible neutrality of blockchains.<br/>

Neutral servers are still centralised, but they use ZKPs and channels on Ethereum to provide service guarantees.

# NeutralChat

NeutralChat is social media for Ethereum on top of a neutral server.<br/>
NeutralChat guarantees (to a degree) that anyone can make a post, and that every post can be found by anyone.<br/>

## Technical Details

### Guarantees

Anyone can buy tickets to access the server at a fixed price.<br/>
Any ticket holder can force the server to respond to its requests, slashing them if they don't.<br/>
To address a `search` request, the server must respond with the relevant posts, and a proof that they are correct.<br/>
To address a `post` request, the server must store the data within the `leeway` period<br/>
The server is forced to post a state root on chain at least every `interval` blocks.<br/>

### Tickets

Tickets are used to make requests.<br/>
Each request costs a fixed and uneditable number of tickets.<br/>
Tickets can be bought onchain at a fixed price of Neu.<br/>
Tickets can also be given away by the server, who signs a message declaring you have them.<br/>
You can prove the number of tickets you have by looking at the ticketbooth contract, or showing the server has signed more to you.<br/>
If you attempt to reuse a ticket, the server can demonstrate that and penalise you some fixed number of tickets.<br/>

### Queue

To force the server to repspond, make a request and put it in the queue by spending a ticket.<br/>
The server must respond onchain within the `response_window`, or else their entire bond will be slashed.<br/>
It costs the server to respond onchain, so they're incentivised to respond offchain.<br/>
Enqueue and dequeue should cost around the same gas to minimize griefing attacks by the client, or censorship by the server.<br/>
In order to enqueue, the request must be dated after the current time.<br/>
In order to dequeue, the response must include a signature of the response body and the request body.<br/>

### Bond

The server holds most of its Neu in a bond which can be slashed for misbahaviour.<br/>
The bond vests over time at a fixed percentage each month, meaning there is always money left in the bond, but the limit of the amount vested approaches the whole bond.<br/>
The bond can be added to at any time.<br/>
The bond can be slashed by a smart contract or by a fraud proof.<br/>
If the bond is slashed by a fraud proof, we call the fraud proof provider a fisherman, and they recieve a reward.<br/>
The fisherman's reward must be small (say, 2% of the slash) to prevent the server operators from slashing themselves to circumvent vesting.<br/>

### Search Fraud

The queue itself does not check the validity of the request or response bodies.<br/>
For search requests, there is a separate contract that identifies fraudulent search responses.<br/>
Anyone who can demonstrate that the server committed search fraud can slash the bond and recieve a fisherman's reward.<br/>
To prove a search fraud the fisherman must:<br/>
    Show a valid search request where the state root is an actual onchain state root from before the `request_date`<br/>
    Show that is a signed response from the server.<br/>
    Show that the response body is invalid.<br/>
        A valid response (body) is a valid ZKP proving that the `query` on the `state` gives a given `result`<br/>

### Discrepancy Check

A post response is just a signed request, therefore the queue implicitly validates the response at dequeue.<br/>
A post response means that the server will store the request within `leeway` blocks of `request_date`.<br/>
A discrepancy is when the server doesn't store a post it said it would within the time period.<br/>
Anyone who can demonstrate a discrepancy can slash the bond and receieve a fisherman's reward.<br/>
To demononstrate a discrepancy, you must provide:<br/>
    A post response<br/>
    An `exact_match` search request with a state root from after `leeway + request_date`<br/>
    Where `query` precisely matches the post response's content<br/>

### State Update

The server must continuously update the onchain state root every `update_period`.<br/>
The bond is slashed if it fails to do this.<br/>
In addition to a new hash, it must provide a ZKP showing that the data is in order, and that the new state is a superset of the old state.

### State Structure

The state is made of slots of fixed size containing a message.
Each message has an ethereum address, a block_number at which it was stored, a `content_length` byte body, and a signature.
The messages are stored in order.
The state root is the merkle root of all the messages.

### Search

There are several types of search, each with a different use case and different cost to the server:
    `exact_match`, `next`, `previous`, `content_substring`
`exact_match` returns a 1 or a 0 depending whether the a message (including metadata) is in the sorted list.
`next` gives the first message stored after a given point in the sorted list.
`previous` gives the first message stored after a given point in the sorted list.
`content_substring` gives the nth message whose body matches a given string.

### Impersonation Fraud

If there is any `exact_match` response where the message has an invalid signature, the server's bond is slashed.