## 📌 Why we set `LinkToken`

In Chainlink VRF (Verifiable Random Function), LINK tokens are required to pay for randomness requests. To simulate or enable this payment mechanism in different environments (local vs testnet), we use the `LinkToken` contract:

- On **testnets** (e.g., Sepolia), a real LINK token contract address is used.
- On **local networks**, a mock version of the LINK token is deployed.

By referencing `LinkToken`, we gain access to its `transferAndCall()` function, which is critical for funding Chainlink VRF subscriptions.

---

## 🔧 What LinkToken does

```solidity
LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
```

This line:

- Transfers LINK tokens to the VRFCoordinator contract
- Automatically calls `onTokenTransfer()` inside the VRFCoordinator
- This function processes the transfer and allocates the LINK to the provided `subscriptionId`

> It essentially allows us to fund our Chainlink VRF account with LINK in a single transaction.

---

## 🔁 How `fundSubscription()` Works

```solidity
function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
    if (block.chainid == LOCAL_CHAIN_ID) {
        // Local development: Direct mock call
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
    } else {
        // Testnet/Mainnet: Transfer LINK to VRF Coordinator
        LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
    }
}
```

### 🧠 Summary of Logic:

- On **local chains**, we directly call the mock's `fundSubscription()` method.
- On **testnets**, we simulate a real LINK deposit by calling `transferAndCall()` on the LINK token contract.

This dual-logic helps keep the funding flow flexible across development and production environments.

