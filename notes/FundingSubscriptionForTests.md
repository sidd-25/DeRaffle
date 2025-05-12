# 🔄 Funding the VRF Subscription (Local Chain Only)

In local testing environments like Anvil, you need to fund the mock Chainlink VRF subscription manually. There are **two approaches**, both of which work. Choose based on your needs:

---

## 🧪 Option 1: Manual Funding Directly in the Test

This approach is done inline within your test setup using `vm.prank`, `mint`, `approve`, and `fundSubscription`:

```solidity
vm.startPrank(msg.sender);
if (block.chainid == LOCAL_CHAIN_ID) {
    LinkToken(link).mint(msg.sender, LINK_BALANCE);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
}
LinkToken(link).approve(vrfCoordinator, LINK_BALANCE);
vm.stopPrank();
```

**Pros:**
- Direct and flexible.
- Great for debugging.

**Cons:**
- Clutters your test logic.
- Duplicates logic if used across multiple test files.

---

## 📦 Option 2: Using a Helper Script (Recommended for Clean Code)

This approach uses your pre-defined `FundSubscription` helper contract:

```solidity
FundSubscription fundSub = new FundSubscription();
fundSub.fundSubscription(vrfCoordinator, subscriptionId, link);
```

**Pros:**
- Keeps test code clean and modular.
- Reusable across deployments and test environments.

**Cons:**
- Slightly abstracted, might be less transparent during early debugging.

---

✅ **Both approaches are correct and functional.**  
For serious testing and maintainability, **prefer the helper-based script approach**.
