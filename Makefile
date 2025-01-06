-include .env

.PHONY: help
.PHONY: all test clean

all : clean install build

# Clean the project
clean:; forge clean

# Install the project
install:; forge install foundry-rs/forge-std openzeppelin/openzeppelin-contracts --no-commit

# Update the dependencies
update:; forge update

# Build the project
build:; forge build

# Test the project
test:; forge test -vvvv --rpc-url $(RPC_URL) --gas-report

# Snapshot the project
snapshot:; forge snapshot

# Anvil
anvil:; forge anvil --fork-url $(RPC_URL)

# Deploy the project
testnet:; forge script script/CypherPup.s.sol --rpc-url $(RPC_URL) --private-key $(OWNER_PRIVATE_KEY) --broadcast -vvvv
simulate:; forge script script/CypherPup.s.sol:CypherPup --rpc-url $(RPC_URL)  -vvvv


 # REFERENCE FOR DEPLOYING A CONTRACT
helloBlockchain:;forge create --rpc-url $(RPC_URL) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --verifier blockscout --verifier-url $(LISK_BLOCKSCOUT_TEST) --private-key $(OWNER_PRIVATE_KEY) --contracts ./src/HelloBlockchain.sol HelloBlockchain --constructor-args "INITIAL MESSAGE" -vvvv