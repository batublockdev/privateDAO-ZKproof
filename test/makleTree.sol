// SPDX-Liciense-Identifier: MIT
pragma solidity ^0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import "lib/poseidon-solidity/contracts/PoseidonT3.sol"; // adjust path as needed
import "../src/makleTreeWithHistory.sol";

contract makleTreeTest is Test {
    uint256 public constant ZERO =
        5365074742933140195701460912837558111746482509126416785866028967095537070591;
    uint256 public constant COMMITMENT =
        20543223265020358312625391328879726074346609467051280159945712475073489703124;
    MerkleTreeWithHistory makleTree;

    function setUp() public {
        // Setup code if neede
        makleTree = new MerkleTreeWithHistory(20); // Initialize with 32 levels
    }

    function test_x() public {
        // Example test case
        uint256[] memory inputs = new uint256[](2);
        uint256 result = PoseidonT3.hash([COMMITMENT, ZERO]);
        console2.log("Poseidon hash result: %s", result);
    }

    function test_insert() public {
        // Test inserting a leaf
        /*makleTree._insert(COMMITMENT);
        console2.log("Inserted at root: %s", makleTree.getLastRoot());
        uint32 index = makleTree._insert(COMMITMENT);
        console2.log("Inserted at index: %s", index);
        assertEq(index, 1); // Assuming this is the first insert
        console2.log("Inserted at root: %s", makleTree.getLastRoot());*/
    }
}
