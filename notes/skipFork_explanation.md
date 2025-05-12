
# Why Tests Failed on Forked Chain and Need for `skipFork` Modifier

## 🔍 Root Cause

These tests failed on a forked chain because they relied on mocked contract behavior tied to hardcoded or deployed addresses — specifically, the Chainlink Oracle address.

### In the Local Environment:
- The address used for the Chainlink Oracle (e.g., `0x...`) is either a mocked contract we deployed ourselves, or a dummy address manually set to simulate oracle behavior.
- Calls to this address return expected mocked responses because we've controlled the setup in our local test suite (e.g., using `vm.etch`, `vm.mockCall`, or deploying a fake oracle).

### On a Forked Chain:
- That same oracle address (e.g., `0x2cF...` on Ethereum mainnet) points to the **real deployed oracle**.
- Our mocked assumptions break because:
  1. The real oracle expects valid Chainlink jobs and off-chain reporting logic.
  2. The test tries to treat the real oracle as a mock (or stub), causing reverts or invalid reads.
  3. The behavior of `read()` or `latestRoundData()` fails due to access control, zero values, or malformed mock data.

## ❗️ Result

The test fails not because of a logic error, but because the assumption that a certain address behaves like a mock does not hold in forked environments.

## ✅ Solution: `skipFork` Modifier

The `skipFork` modifier was introduced to **gracefully skip** these tests when `block.chainid != LOCAL_CHAIN_ID`, ensuring we **only run tests with mocked dependencies on the local chain**, and avoid misleading failures on forked mainnet or testnet.

### Solidity Code
```solidity
modifier skipFork {
    if (block.chainid != LOCAL_CHAIN_ID) {
        return;
    } else {
        _;
    }
}
```

## 📌 TL;DR

- These tests expected mock behavior at specific addresses.
- On a forked chain, those addresses map to real deployed contracts, not mocks.
- This causes unexpected failures, which are bypassed using `skipFork`.
