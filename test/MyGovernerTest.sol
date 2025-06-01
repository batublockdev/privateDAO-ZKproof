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
        9544268642844573704226647894835027779097887973385979818262426097926729903982;
    uint256 public constant COMMITMENT2 =
        5581525453447415493315491882928005573898416079263491592050413242111209948978;
    uint256 public constant COMMITMENT3 =
        21879835473289089405366633954264833758077734612338952786509573456282948697519;
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
    address public VOTER3 = makeAddr("voter3");

    function setUp() public {
        token = new MyToken();
        verifier = new Groth16Verifier();
        token.mint(VOTER);
        token.mint(VOTER2);
        token.mint(VOTER3);

        vm.prank(VOTER);
        token.delegate(VOTER);

        vm.prank(VOTER2);
        token.delegate(VOTER2);

        vm.prank(VOTER3);
        token.delegate(VOTER3);
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
        vm.prank(VOTER2);
        governor.summitVote(proposalId, COMMITMENT2);
        vm.prank(VOTER3);
        governor.summitVote(proposalId, COMMITMENT3);
        //voter 1
        uint256[8] memory proof = [
            8039392040583973212913521282298405713780911044316692617305120406279267566159,
            18575181894848113026947223395252661979091234747992899641858885089981960493356,
            6496198034457368953480458198642800745035746287045747461547622829834111110782,
            20020140623192545529141979051642228323371334728966868959774689347615088011189,
            17736612729908494679937357708288253427886801729235915080180115876091497283296,
            11573824621719536551478675552232798964923828003725997505151739113626960191910,
            6652102014125986544991973994186914544870814079226337279068751921155057403470,
            20179670554292575385000782915063214653179328810865057338933305173262706218541
        ];
        uint256 nullfier = 21722496458489112093414803228554251805332267507751634458902680792396968264905;
        //voter 2
        uint256[8] memory proof_2 = [
            21625032142323420377067950748506637244992978995273564326137821680365291752071,
            14630835012503899302294981593697811527948276691727061023317360928537162288249,
            3595100141988309324949223455978491177216704760569021596637824424578777187356,
            8216113741060252423130351824574414914797368278984464746650397580449393640462,
            10141384868913629057367419272887986422240309836816258773492077270695437405285,
            14598786089502844989287558098739753196962353440839385837255869490083759287548,
            6536152563004551222755870687738535174549158701517967516907070512627613020493,
            6959609050297867875167685488332268776143805441708088606033095445319162166499
        ];
        uint256 nullfier_2 = 4982172419054866605926794717439024746818817514933953857957654614230575504844;
        //voter 3
        //voter 2
        uint256[8] memory proof_3 = [
            19073309605411017561459936654026047492647771712935208663978390068896186755230,
            14263999970633864548714474815648706245308644559074455073997457545264535633427,
            3623654297991580309357643140053371395530824620590334166456646200727740351620,
            9225478961984932689401894844151689601462369102463600081675215811481174187235,
            8086703251339092864310611395101049425490577253385874747960060286918711238695,
            16488100863457434000952597214870227473895733602046511651159972506211710440905,
            18234623521422527399084940299849334616159333838507886262838125772108603018828,
            14922807912532646637237544977565590615763116654905764366247463886130670979239
        ];
        uint256 nullfier_3 = 3632311455054646310885570210872861156047878303809142251571035012624167257762;
        vm.startPrank(VOTER2);
        uint256[3][] memory data = new uint256[3][](3);
        data[0] = [proposalId, nullfier, voteWay];
        data[1] = [proposalId, nullfier_2, voteWay];
        data[2] = [proposalId, nullfier_3, 0];

        uint256[8][] memory _proofs = new uint256[8][](3);
        _proofs[0] = proof;
        _proofs[1] = proof_2;
        _proofs[2] = proof_3;
        governor._castVotes(data, _proofs);

        /*governor.castVoteWithReason(
            proposalId,
            proof,
            nullfier,
            voteWay,
            reason
        );
        governor.castVoteWithReason(
            proposalId,
            proof_2,
            nullfier_2,
            voteWay,
            reason
        );
        governor.castVoteWithReason(proposalId, proof_3, nullfier_3, 0, reason);*/
        vm.stopPrank();

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
