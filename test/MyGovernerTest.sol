// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/Governor.sol";
import {MyToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";
import {Groth16Verifier} from "../src/ZKPVerifier.sol";

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
        //governor.castVoteWithReason(proposalId, 333, voteWay, reason);
        console.log("root: %s", governor.getLastRoot(proposalId));
        assertEq(governor.getLastRoot(proposalId), ZERO);
        vm.prank(VOTER);
        governor.summitVote(proposalId, COMMITMENT);
        governor.getLastRoot(proposalId);
        console.log("root: %s", governor.getLastRoot(proposalId));
        uint256[8] memory proof = [
            19784089813153104539733794791124798902709579659651807205985955776199460597453,
            10731522097037926826426386698045725621692488854983477387207460367760933268761,
            16388268542266325098598021934781070579159367306707450650321201243488134287249,
            21419302285973490267464830229133095275719267507207696839934608461308859056456,
            6676622145037186258886481996585942089697162517535709030266263432813638803340,
            4178610333791985931854082107266312118125667565414451316631966506505238701637,
            896755678228160637171591548836471126782712227095522396489866182417469727191,
            14698831525816631146985423211453505076460221178970876513193623307341937747945
        ];
        uint256 nullfier = 1568331803839604787979069408914956745900061282541867904312135814170319910966;
        uint256 rootx = governor.getLastRoot(proposalId);
        uint[2] memory _pA = [
            19784089813153104539733794791124798902709579659651807205985955776199460597453,
            10731522097037926826426386698045725621692488854983477387207460367760933268761
        ];
        uint[2][2] memory _pB = [
            [
                21419302285973490267464830229133095275719267507207696839934608461308859056456,
                16388268542266325098598021934781070579159367306707450650321201243488134287249
            ],
            [
                4178610333791985931854082107266312118125667565414451316631966506505238701637,
                6676622145037186258886481996585942089697162517535709030266263432813638803340
            ]
        ];
        uint[2] memory _pC = [
            896755678228160637171591548836471126782712227095522396489866182417469727191,
            14698831525816631146985423211453505076460221178970876513193623307341937747945
        ];
        uint[2] memory _pubSignals = [
            ROOT,
            1568331803839604787979069408914956745900061282541867904312135814170319910966
        ];
        bool dio = verifier.verifyProof(_pA, _pB, _pC, _pubSignals);
        assertTrue(dio, "Proof verification failed");
        assertNotEq(governor.getLastRoot(proposalId), ROOT);

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
