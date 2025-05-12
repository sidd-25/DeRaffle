-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :; forge install cyfrin/foundry-devops --no-commit && forge install smartcontractkit/chainlink-brownie-contracts --no-commit && forge install foundry-rs/forge-std --no-commit && forge install transmissions11/solmate --no-commit

install :; \
	[ -d lib/foundry-devops ] && (git rm -rf --cached lib/foundry-devops || true) && rm -rf lib/foundry-devops || true; \
	[ -d lib/chainlink-brownie-contracts ] && (git rm -rf --cached lib/chainlink-brownie-contracts || true) && rm -rf lib/chainlink-brownie-contracts || true; \
	[ -d lib/forge-std ] && (git rm -rf --cached lib/forge-std || true) && rm -rf lib/forge-std || true; \
	[ -d lib/solmate ] && (git rm -rf --cached lib/solmate || true) && rm -rf lib/solmate || true; \
	forge install cyfrin/foundry-devops && \
	forge install smartcontractkit/chainlink-brownie-contracts && \
	forge install foundry-rs/forge-std@v1.8.2 && \
	forge install transmissions11/solmate

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_URL) --account realKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
