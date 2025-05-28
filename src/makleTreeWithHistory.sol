// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "lib/poseidon-solidity/contracts/PoseidonT3.sol"; // adjust path as needed

contract MerkleTreeWithHistory {
    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction

    struct MakleTree {
        mapping(uint256 => uint256) filledSubtrees;
        uint256 root;
        uint32 nextIndex;
    }
    mapping(uint256 proposalId => MakleTree) public _proposalTrees;

    constructor(uint32 _levels) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;
    }

    function createMakleTree(uint256 proposalId) public {
        for (uint32 i = 0; i < levels; i++) {
            _proposalTrees[proposalId].filledSubtrees[i] = zeros(i);
        }

        _proposalTrees[proposalId].root = zeros(levels - 1);
    }

    /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
    function hashLeftRight(
        uint256 _left,
        uint256 _right
    ) public pure returns (uint256) {
        uint out = PoseidonT3.hash([_left, _right]);
        return out;
    }

    function _insert(
        uint256 proposalId,
        uint256 _leaf
    ) internal returns (uint32 index) {
        uint32 _nextIndex = _proposalTrees[proposalId].nextIndex;
        require(
            _nextIndex != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = _nextIndex;
        uint256 currentLevelHash = _leaf;
        uint256 left;
        uint256 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                _proposalTrees[proposalId].filledSubtrees[i] = currentLevelHash;
            } else {
                left = _proposalTrees[proposalId].filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;
        }

        _proposalTrees[proposalId].root = currentLevelHash;
        _proposalTrees[proposalId].nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    /**
    @dev Returns the last root
  */
    function getLastRoot(uint256 proposalId) public view returns (uint256) {
        return _proposalTrees[proposalId].root;
    }

    /// @dev provides Zero (Empty) elements for a MiMC MerkleTree. Up to 32 levels
    function zeros(uint256 i) public pure returns (uint256) {
        if (i == 0)
            return
                uint256(
                    5365074742933140195701460912837558111746482509126416785866028967095537070591
                );
        else if (i == 1)
            return
                uint256(
                    18927995262277541656172313965917959133749249173481326288359404073453342459520
                );
        else if (i == 2)
            return
                uint256(
                    16731048699270784421706570066001991137631760108429146124137121216236553054391
                );
        else if (i == 3)
            return
                uint256(
                    16538499595934659613727544616962797785338492501618747306146816584688577735208
                );
        else if (i == 4)
            return
                uint256(
                    9080356992685742511681529878226919830400349732756896631827555189762739734491
                );
        else if (i == 5)
            return
                uint256(
                    5424144409132066577541240512439621178657103249409002506486103738618538352024
                );
        else if (i == 6)
            return
                uint256(
                    10544296693406531387206535330554893730829540929428087193592756592216676445216
                );
        else if (i == 7)
            return
                uint256(
                    7564988964993902948097824678805225006987812851830016626680599597402005451957
                );
        else if (i == 8)
            return
                uint256(
                    12169719382686741916580483745316623687880402026431235449348059358607961733224
                );
        else if (i == 9)
            return
                uint256(
                    8406940278843123175743832327158906184461007565351952961240403202786066254437
                );
        else if (i == 10)
            return
                uint256(
                    18095170724440081982596227705073746612735437036256299083752673311093685115565
                );
        else if (i == 11)
            return
                uint256(
                    12494921685926131790120916419089462187828486801312615440551414562915682918055
                );
        else if (i == 12)
            return
                uint256(
                    10982166978621049276500916207228131554783228711662971846611531133859682131754
                );
        else if (i == 13)
            return
                uint256(
                    20706006017932272733008726576435564635242694158389807366729547655972642914556
                );
        else if (i == 14)
            return
                uint256(
                    12387411678914679768595095911604733054258673148265834445738162148229762835545
                );
        else if (i == 15)
            return
                uint256(
                    4645457020147420961926028699764295047993990626023916925718742337202088609186
                );
        else if (i == 16)
            return
                uint256(
                    20031172315068130033417068040619844856054469898708347831004393380441627976110
                );
        else if (i == 17)
            return
                uint256(
                    10706546104333770657460492059417658198254511559412115282441046503143202741181
                );
        else if (i == 18)
            return
                uint256(
                    11849011169801684430469139138252284578555021442080969739652766930478906494558
                );
        else if (i == 19)
            return
                uint256(
                    3314372264187560584702178823305973219176593083766293720214567837146802335937
                );
        else if (i == 20)
            return
                uint256(
                    1976389223243078417398278543048130277804852592158378794293220333410109017266
                );
        else revert("Index out of bounds");
    }
}
