pragma circom 2.1.6;

include "merkleTree.circom";
include "../circomlib/circuits/poseidon.circom";

template CommitmentHasher () {
    signal input secret;
    signal input secretNullifier;
    signal input vote;
    signal input address;
    
    
    signal output nullifierHash;
    signal output mycommitment;
    
    // Computes nullifier hash = Poseidon(nullifier, address)
    component hashNullifier = Poseidon(2);
    hashNullifier.inputs[0] <== secretNullifier;
    hashNullifier.inputs[1] <== address;
    
    nullifierHash <== hashNullifier.out;
    
    // Computes commitment hash = Poseidon(nullifier, vote, secret)
    component hashCommitment = Poseidon(3);
    hashCommitment.inputs[0] <== nullifierHash;
    hashCommitment.inputs[1] <== vote;
    hashCommitment.inputs[2] <== secret;
    
    mycommitment <== hashCommitment.out;
}


// Verifies that commitment that corresponds to given secret and nullifier is included in the merkle tree of deposits
template Withdraw(levels) {
    signal input root;
    signal input nullifierHash;
    
    signal input address;
    signal input secretNullifier;
    signal input vote;
    signal input secret;
    
    signal input pathElements[levels];
    signal input pathIndices[levels];
    
    component hasher = CommitmentHasher();
    hasher.vote <== vote;
    hasher.address <== address;
    hasher.secretNullifier <== secretNullifier;
    hasher.secret <== secret;
    hasher.nullifierHash === nullifierHash;
    
    component tree = MerkleTreeChecker(levels);
    tree.leaf <== hasher.mycommitment;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }
    
}

component main { public [ root, nullifierHash, vote ] } = Withdraw(20);
    