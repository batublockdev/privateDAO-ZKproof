// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/Governor.sol";
import {MyToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";
import {Groth16Verifier} from "../src/ZKP_Verifier.sol";

contract MyGovernorTest is Test {
    MyToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;
    Groth16Verifier verifier;

    uint256 public constant ZERO =
        3314372264187560584702178823305973219176593083766293720214567837146802335937;
    uint256 public constant ROOT =
        5299859699350649085561259447857667476237120085959672604875330521362396176131;
    uint256 public constant COMMITMENT =
        8087964349687519452738347412624895063811326932727551702759131670194990317379;
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
        verifier = new Groth16Verifier();
        token.mint(VOTER);
        token.mint(VOTER2);

        vm.prank(VOTER);
        token.delegate(VOTER);
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(token, timelock, 20, address(verifier));
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
        vm.prank(VOTER);
        governor.summitVote(proposalId, COMMITMENT);
        uint256[8] memory proof = [
            1291994846396078613044574897177224119187603235626790482382986709270615610660,
            11418028624131748828325833568108100807637292497137959178892501834812267781589,
            15307144925250882126508909830121112268311797725366591107187283040749027038051,
            19121243146002381672368451937259115381293170521977261710324651706105037953130,
            546095556106703638693576158784533379952904102891789936496015709648147352514,
            3925174758087334945311755721237858927615284060728218310924261845762381850125,
            4446524021056083204779206370924040594838291933571077817049533252467235158133,
            14226643594824731874337614245245804908106811669913443099387467886105998358741
        ];
        uint256 nullfier = 1568331803839604787979069408914956745900061282541867904312135814170319910966;
        vm.prank(VOTER2);
        governor.castVoteWithReason(
            proposalId,
            proof,
            nullfier,
            voteWay,
            reason
        );
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
