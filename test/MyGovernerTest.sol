// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/Governor.sol";
import {MyToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    MyToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    uint256 public constant ZERO =
        3314372264187560584702178823305973219176593083766293720214567837146802335937;
    uint256 public constant COMMITMENT =
        20543223265020358312625391328879726074346609467051280159945712475073489703124;
    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public VOTER = makeAddr("voter");
    address public VOTER2 = makeAddr("voter2");

    function setUp() public {
        token = new MyToken();
        token.mint(VOTER);
        token.mint(VOTER2);

        vm.prank(VOTER);
        token.delegate(VOTER);
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(token, timelock, 20);
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = "Store 1 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "store(uint256)",
            valueToStore
        );
        addressesToCall.push(address(box));
        values.push(0);
        functionCalls.push(encodedFunctionCall);
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        console.log("Proposal State:", uint256(governor.state(proposalId)));
        // governor.proposalSnapshot(proposalId)
        // governor.proposalDeadline(proposalId)

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "I like a do da cha cha";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER2);
        governor.castVoteWithReason(proposalId, 333, voteWay, reason);
        console.log("root: %s", governor.getLastRoot(proposalId));
        assertEq(governor.getLastRoot(proposalId), ZERO);
        vm.prank(VOTER);
        governor.summitVote(proposalId, COMMITMENT);
        governor.getLastRoot(proposalId);
        console.log("root: %s", governor.getLastRoot(proposalId));
        assertNotEq(governor.getLastRoot(proposalId), ZERO);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(box.retrieve() == valueToStore);
    }
}
