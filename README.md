# DeRaffle: Decentralized Raffle Smart Contract

## Overview

**DeRaffle** is a fully decentralized, verifiably fair raffle (lottery) system built on Ethereum. Leveraging Chainlink VRF for provable randomness, DeRaffle ensures transparent winner selection and robust security. The project is developed using [Foundry](https://book.getfoundry.sh/) for rapid, reliable smart contract development, testing, and deployment.

---

## Features

- **Provably Fair Raffle:** Uses Chainlink VRF for unbiased, tamper-proof randomness.
- **Automated Deployment & Testing:** Scripts and tests written in Solidity, managed by Foundry.
- **Modular & Extensible:** Clean separation of contract logic, deployment scripts, and configuration.
- **Comprehensive Test Suite:** Includes unit tests and mocks for external dependencies.
- **Deployment Artifacts:** Broadcasts and logs for reproducible deployments on testnets.

---

## Directory Structure

```plaintext
src/                # Core smart contracts (Raffle.sol)
script/             # Deployment and interaction scripts
test/
  unit/             # Unit tests for contracts
  mocks/            # Mock contracts (e.g., LinkToken)
broadcast/          # Deployment artifacts (JSON)
notes/              # Technical notes and explanations
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for Chainlink node interactions, if needed)
- An Ethereum wallet (e.g., MetaMask)
- Access to Sepolia or other testnet

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/DeRaffle.git
cd DeRaffle

# Install Foundry dependencies
forge install
```

---

## Usage

### 1. Compile Contracts

```bash
forge build
```

### 2. Run Tests

```bash
forge test
```

### 3. Deploy to Testnet

Update your environment variables and Foundry config as needed, then:

```bash
forge script script/DeployRaffle.s.sol --rpc-url <SEPOLIA_RPC_URL> --broadcast --verify
```

Deployment artifacts will be saved in the `broadcast/` directory.

### 4. Interact with the Contract

Use the provided scripts in `script/Interactions.s.sol` or interact via Etherscan, Foundry, or your preferred tool.

---

## Technical Highlights

- **Chainlink VRF Integration:** Ensures randomness in winner selection is verifiable and cannot be manipulated.
- **Mocking & Testing:** Includes mocks for Chainlink tokens and services, enabling full local test coverage.
- **Automated Scripts:** Deployment and interaction scripts are written in Solidity for seamless integration with Foundry.
- **Documentation:** In-depth notes and explanations provided in the `notes/` directory.

---

## Example: Raffle Flow

1. Users enter the raffle by sending ETH.
2. When the raffle ends, a random winner is selected using Chainlink VRF.
3. The winner receives the entire pot, and the raffle resets for the next round.

---

## Project Philosophy

- **Security First:** Follows best practices for smart contract security and testing.
- **Transparency:** All randomness and winner selection are on-chain and verifiable.
- **Developer Experience:** Clean, modular codebase with clear documentation and automation.

---

## Contributing

Contributions are welcome! Please open issues or pull requests for improvements, bug fixes, or new features.

---

## License

[MIT](LICENSE)

## Acknowledgements

- [Chainlink](https://chain.link/)
- [Foundry](https://book.getfoundry.sh/)
- [Solmate](https://github.com/transmissions11/solmate)
