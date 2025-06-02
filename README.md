
# 🛡️ Private DAO with Anonymous Voting

A Solidity-based **private DAO** that enables **anonymous, verifiable, and equal-weight voting** using commitment schemes, Merkle trees, and zero-knowledge proofs.  

**Inspired by [Tornado Cash](https://tornado.cash/)**, this system borrows privacy mechanics to enable unlinkable votes while maintaining the integrity of the vote count.

---

## 🧠 Overview

This project implements a **two-phase private voting mechanism** where voters submit a **cryptographic commitment** and later reveal their vote using a **zero-knowledge proof**. The DAO ensures:
- 🔒 **Private vote submission** with no on-chain link to the voter
- 🧮 **Verifiable vote counts** using zkSNARKs
- ⚖️ **Equal voting power** through 1 token per voter
- ✅ **No double voting** enforced via nullifiers

---

## 🔄 Voting Process

### 1. **Summit Vote (Commit Phase)**

```solidity
function summitVote(uint256 proposalId, uint256 commitment) public returns (uint256)
```

- Voter submits a cryptographic commitment to their vote.
- The commitment is inserted into a per-proposal **Merkle tree**, hashed with **Poseidon** (not MiMC).
- Voter must own **exactly one token**.
- No one, not even the DAO, can link a vote to the user.

### 2. **Cast Vote (Reveal + ZK Proof)**

```solidity
function _castVote(
    uint256 proposalId,
    uint256[8] memory _proof,
    uint256 nullifier,
    uint8 support,
    string memory reason,
    bytes memory params
) internal returns (uint256)
```

- A zkSNARK proof is submitted that:
  - Validates the vote is part of the Merkle tree.
  - Proves the vote direction (`support`) and uniqueness (`nullifier`).
- Vote is tallied with a fixed weight (`1e18`), avoiding voter fingerprinting.

### 3. **Batch Voting (Optional)**

```solidity
function _castVotes(uint256[3][] memory data, uint256[8][] memory _proofs) public returns (uint256)
```

- Allows multiple votes to be revealed in one transaction to reduce gas costs.

---

## 🔒 Privacy Guarantees

- ✅ **No address is linked** to a vote.
- ✅ **Merkle roots** hide the origin of commitments.
- ✅ **Poseidon hash** ensures SNARK-friendly and efficient tree hashing.
- ✅ **Nullifiers** prevent double-voting.
- ✅ **Equal vote weights** avoid linking identities via influence.

---

## 🧰 Tech Stack

- 📦 [Solidity](https://docs.soliditylang.org/)
- 🏛️ [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/api/governance)
- 🔐 [Groth16 zkSNARKs](https://eprint.iacr.org/2016/260.pdf)
- 🌲 [Poseidon Hash](https://eprint.iacr.org/2019/458) in Circom-based Merkle trees
- 🧪 [Circom](https://docs.circom.io/) for ZK circuit design
- 🔧  [Foundry](https://book.getfoundry.sh/)

---

## 📁 Project Structure

```
contracts/
  Governor.sol             # Custom DAO logic
  MerkleTreeWithHistory.sol # Poseidon-based Merkle tree
  Verifier.sol             # ZK proof verifier
  VotingToken.sol          # 1 token = 1 voter

circuits/
  voteProof.circom         # zkSNARK circuit for voting logic

test/
  Governor.t.sol           # Solidity tests for summit and reveal



```

---

## ✅ Features

- ✅ Anonymous vote submission via commitment scheme
- ✅ zkSNARK-based vote revealing and verification
- ✅ Batch vote casting to save gas
- ✅ Merkle tree with Poseidon hash for efficiency
- ✅ Tornado Cash-style nullifier protection
- ✅ Full test coverage (contracts & circuits)

---

## 🧪 Tests

All critical functionalities are covered in the test suite:

- ✅ Valid/invalid commitment submissions
- ✅ Merkle tree updates with Poseidon hash
- ✅ ZK proof verification via Groth16
- ✅ Double-vote detection via nullifier
- ✅ Batch casting multiple valid votes

Run tests with:

```bash
# Hardhat
npx hardhat test

# or Foundry
forge test
```

---

## 🔍 Want to See the ZK Circuit?

Yes, it’s open!  
The `CIRCOM/` folder includes the full Circom implementation, constraints, and example inputs for generating and verifying proofs.

---

## 🧾 License

MIT © 2025
