# Neutral

Neutral is a suite of tools for building credibly neutral servers.

Existing servers are centralised and can arbitrarily withhold service, give false responses, or drop your data.
Blockchains, on the other hand are credibly neutral but they suffer from scalability problems, especially for data (as opposed to computation).
Neutral servers are a middleground with almost as much scalability as traditional servers, and some of the credible neutrality of blockchains.

Neutral servers are still centralised, but they use channels and ZKPs on top of Ethereum to provide service guarantees.

# NeutralChat

NeutralChat is social media for Ethereum on top of a neutral server.
NeutralChat guarantees* that anyone can make a post, and that every post can be found by anyone.

## Technical Details

### Guarantees

Anyone can buy tickets to access the server at a fixed price.
Any ticket holder can force the server to respond to its requests, slashing them if they don't.
If a ticket holder makes a `get posts`, the server must respond with the relevant posts, and a proof that they are correct.
If a ticket holder makes a `post` request, the server must respond with a declaration that they will intsert the post at a given time.
If the server makes a false declaration, they are slashed.
The server is forced to post a state root on chain at least every `interval` blocks.

### Tickets

Tickets are used to make requests.
Each request costs a fixed and uneditable number of tickets.
Tickets can be bought onchain at a fixed price of Neu.
Tickets can also be given away by the server, who signs a message declaring you have them.
You can prove the number of tickets you have by showing your looking at the contract, or showing the server has signed more to you.
If you attempt to reuse a ticket, the server can demonstrate that and penalise you some fixed number of tickets.

### Queue

To force the server to repspond, make a request and put it in the queue by spending a ticket.
The server will respond onchain within the `response_window`, or else their entire bond will be slashed.
It costs the server to respond onchain, so they're incentivised to respond offchain.
Enqueue and dequeue should cost around the same gas to mimize griefing attacks by the client, or censorship by the server.
In order to enqueue, the request must be dated after the current time.
In order to dequeue, the response must include a signature of the response body and the request body.

### Bond

The server holds most of its Neu in a bond which can be slashed for misbahaviour.
The bond vests over time at a fixed percentage each month, meaning there is always some bond, but every part of the bond is eventually accessible.
The bond can be added to at any time.
The bond can be slashed by a smart contract or by a fraud proof.
If the bond is slashed by a fraud proof, we call the fraud proof provider a fisherman, and they recieve a reward.
The fisherman's reward must be small (say, 2% of the slash) to prevent the server operators from slashing themselves to circumvent vesting.

### Search Verifier

The queue itself does not check the semantic validity of the response.
For search requests, there is a separate contract that verifies that the search response is correct.
Anyone who can demonstrate that the server made an invalid search response can slash the bond and recieve a fisherman's reward.
The search verifier ensures that:
    The state root requested is an actual onchain state root from before the `request_date`
    The response body includes a valid ZKP proving that the `query` on the `state` gives a given `result`

### Discrepancy Check

A post response is just a signed request, therefore the queue implicitly validates the reponse at dequeue.
A post response means that the server will store the request within `leeway` blocks of `request_date`.
A discrepancy is when the server doesn't store a post it said it would within the time period.
Anyone who can demonstrate a discrepancy can slash the bond and receieve a fisherman's reward.
To demononstrate a discrepancy, you must provide:
    A post response
    A search request with a state root from after `leeway + request_date`
    Where `query` precisely matches the post response's content

### State Update

The server must continuously update the onchain state root every `update_period`.
The bond is slashed if it fails to do this.