//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "/Users/ishan/.brownie/packages/OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC20/ERC20.sol";

contract GovernorVoting {
    address contractOwner;

    mapping(address => bool) public nomination;
    mapping(address => uint256) public votes;
    mapping(address => mapping(address => uint256)) public voteMap;
    address[] registration;
    address[] nominationLst;
    mapping(address => bool) registerMap;

    uint256 nominationCost;
    IERC20 citizenToken;

    // winner booleans
    mapping(address => bool) winnerMap;
    address[11] winnerLst;
    bool electionDone = false;

    // add more events
    event Nomination(address nominee);
    event Winners(address[11] winners);

    constructor(uint256 _nominationCost, IERC20 _citizenToken) {
        nominationCost = _nominationCost;
        citizenToken = _citizenToken;
        contractOwner = msg.sender;
    }

    function register() public {
        require(
            citizenToken.balanceOf(msg.sender) >= 100,
            "user needs 100 valid citizenTokens"
        );
        require(registerMap[msg.sender] == false, "already registered");
        registration.push(msg.sender);
        registerMap[msg.sender] = true;
    }

    function nominate(address nominee) public payable {
        require(registerMap[msg.sender] == true, "user needs to be registered");
        require(
            citizenToken.balanceOf(nominee) > 0,
            "nominee is not a valid citizen"
        );
        require(nomination[nominee] == false, "already nominated");
        nomination[nominee] = true;
        nominationLst.push(nominee);
        emit Nomination(nominee);
    }

    function vote(address nominee, uint256 voteCount) public payable {
        require(registerMap[msg.sender] = true, "voter needs to be registered");
        require(nomination[nominee] == true, "not a valid nominee");
        require(
            citizenToken.allowance(msg.sender, address(this)) > voteCount,
            "not enough allowance"
        );
        citizenToken.transferFrom(msg.sender, address(this), voteCount);
        votes[nominee] += voteCount;
        voteMap[nominee][msg.sender] += voteCount;
    }

    function _redistribute() private {
        for (uint256 i = 0; i < nominationLst.length; i++) {
            address nominee = nominationLst[i];
            if (votes[nominee] != 0) {
                for (uint256 j = 0; j < registration.length; j++) {
                    address voter = registration[j];
                    if (voteMap[nominee][voter] > 0) {
                        citizenToken.transfer(voter, voteMap[nominee][voter]);
                    }
                }
            }
        }
    }

    function declare() public returns (address[11] memory) {
        require(
            contractOwner == msg.sender,
            "can only be called by central contract"
        );
        require(electionDone == false, "Election has already been declared");
        for (uint256 i = 0; i < 11; i++) {
            uint256 maxVote = 0;
            address currWinner;
            for (uint256 j = 0; j < nominationLst.length; j++) {
                if (
                    votes[nominationLst[j]] >= maxVote &&
                    winnerMap[nominationLst[j]] == false
                ) {
                    currWinner = nominationLst[j];
                    maxVote = votes[nominationLst[j]];
                }
            }
            winnerMap[currWinner] = true;
            winnerLst[i] = currWinner;
        }
        _redistribute();
        electionDone = true;
        emit Winners(winnerLst);
        return winnerLst;
    }

    function getConstituency(address winner)
        public
        view
        returns (
            address[] memory voters,
            uint256[] memory voteCount,
            uint256 totalVotes
        )
    {
        require(electionDone == true, "election is not over");
        require(winnerMap[winner] == true, "given address is not a winner");
        uint256 arraySize = 0;
        for (uint256 i = 0; i < registration.length; i++) {
            if (voteMap[winner][registration[i]] > 0) {
                arraySize = arraySize + 1;
            }
        }
        address[] memory constituentVoters = new address[](arraySize);
        uint256[] memory voterCounts = new uint256[](arraySize);
        uint256 totalWinnerVotes = 0;

        uint256 arrayCounter = 0;
        for (uint256 i = 0; i < registration.length; i++) {
            if (voteMap[winner][registration[i]] > 0) {
                constituentVoters[arrayCounter] = registration[i];
                voterCounts[arrayCounter] = voteMap[winner][registration[i]];
                totalWinnerVotes += voteMap[winner][registration[i]];
                arrayCounter += 1;
            }
        }
        return (constituentVoters, voterCounts, totalWinnerVotes);
    }
}
