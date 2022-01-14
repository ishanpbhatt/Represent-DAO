//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "./CitizenToken.sol";

contract Impeachment {
    address governor;
    address contractOwner;
    CitizenToken govToken;
    mapping(address => bool) registrationMap;
    address[] registeredVoters;

    uint256 totalVotes = 0;
    uint256 impeachVotes = 0;
    mapping(address => uint256) yesVoteMap;
    mapping(address => uint256) noVoteMap;

    constructor(
        address _governor,
        address _owner,
        CitizenToken _govToken
    ) {
        governor = _governor;
        contractOwner = _owner;
        govToken = _govToken;
    }

    function register() public {
        require(registrationMap[msg.sender] == false, "already registered");
        require(govToken.balanceOf(msg.sender) > 0, "need to be a citizen");
        registrationMap[msg.sender] = true;
        registeredVoters.push(msg.sender);
    }

    function vote(uint256 numVotes, bool yesVote) public {
        require(
            registrationMap[msg.sender] == true,
            "need non-zero balance to vote"
        );
        require(
            govToken.allowance(msg.sender, address(this)) >= numVotes,
            "not sufficient allowance"
        );
        govToken.transferFrom(msg.sender, address(this), numVotes);

        totalVotes += numVotes;
        if (yesVote == true) {
            impeachVotes += numVotes;
            yesVoteMap[msg.sender] += numVotes;
        } else {
            noVoteMap[msg.sender] += numVotes;
        }
    }

    function getVoters()
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory voters = new address[](registeredVoters.length);
        uint256[] memory yesVotes = new uint256[](registeredVoters.length);
        uint256[] memory noVotes = new uint256[](registeredVoters.length);
        for (uint256 i = 0; i < registeredVoters.length; i++) {
            voters[i] = registeredVoters[i];
            yesVotes[i] = yesVoteMap[registeredVoters[i]];
            noVotes[i] = noVoteMap[registeredVoters[i]];
        }
        return (voters, yesVotes, noVotes);
    }

    function poll()
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            impeachVotes * 100 >= totalVotes * 75,
            impeachVotes,
            totalVotes
        );
    }

    function getGovernor() public view returns (address) {
        return governor;
    }

    function redistribute() public {
        require(msg.sender == contractOwner);
        for (uint256 i = 0; i < registeredVoters.length; i++) {
            uint256 totalCoins = yesVoteMap[registeredVoters[i]] +
                noVoteMap[registeredVoters[i]];
            govToken.transfer(registeredVoters[i], totalCoins);
        }
    }
}
