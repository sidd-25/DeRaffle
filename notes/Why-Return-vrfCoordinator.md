
# Why Return `vrfCoordinator` from a Function Even When We Already Have It?

In Solidity scripts (especially deployment or interaction scripts), it's common to pass around values like the address of the `vrfCoordinator`. You might wonder:

> "If I already have `vrfCoordinator` inside the function, why return it?"

Let’s compare two approaches to understand the difference.

---

## ✅ Version: With Returning `vrfCoordinator`

```solidity
function createSubscriptionUsingConfig() public returns (uint256, address) {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

    (uint256 subId, ) = CreateSubscription(vrfCoordinator);
    return (subId, vrfCoordinator);
}

function CreateSubscription(address vrfCoordinator) external returns (uint256, address) {
    console.log("Creating Subscription on chainId:", block.chainid);
    vm.startBroadcast();
    uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();

    console.log("Created Subscription with ID:", subId);
    return (subId, vrfCoordinator);
}
```

### ✅ Usage:

```solidity
(uint256 subId, address vrfAddr) = createSubscriptionUsingConfig();
// Use both subId and vrfAddr easily
```

---

## ❌ Version: Without Returning `vrfCoordinator`

```solidity
function createSubscriptionUsingConfig() public returns (uint256) {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

    uint256 subId = CreateSubscription(vrfCoordinator);
    return subId;
}

function CreateSubscription(address vrfCoordinator) public returns (uint256) {
    console.log("Creating Subscription on chainId:", block.chainid);
    vm.startBroadcast();
    uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();

    console.log("Created Subscription with ID:", subId);
    return subId;
}
```

### ❌ Usage:

```solidity
uint256 subId = createSubscriptionUsingConfig();
// But I need the vrfCoordinator again...
// So I have to do this:
HelperConfig helper = new HelperConfig();
address vrfAddr = helper.getConfig().vrfCoordinator;
```

---

## 🚨 Downsides of Not Returning It

- Repeated logic (e.g., fetching `vrfCoordinator` again)
- Less reusable function output
- Harder to chain operations
- Not friendly for debugging or logging

---

## 🧠 Real Analogy

> You're baking a cake using an oven your friend brought. If they only give you the cake, and later you want to bake something else in the same oven—you’ll need to figure out which oven they used all over again.

Returning both the cake (subId) and the oven (vrfCoordinator) makes life easier.

---

## ✅ Summary

Returning `vrfCoordinator` even when you already have it inside the function makes your code:

- More modular
- Easier to debug
- Less repetitive
- More expressive for the caller

---

## 📝 When Can You Skip Returning It?

- If `vrfCoordinator` is never reused
- If you don’t need it outside the function at all

But when in doubt—**be explicit** and return it.
