//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "/Users/ishan/.brownie/packages/OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC721/ERC721.sol";

contract GovernorProposal {
    // Governors
    address[11] governors;
    mapping(address => bool) isGovernor;

    uint256 proposalCount = 0;
    uint256 proposalLength;

    // Proposal Information
    mapping(uint256 => bool) isActive;
    mapping(uint256 => uint256) endContract;
    mapping(uint256 => string) proposalInfo;
    mapping(uint256 => uint256) yesVotes;
    mapping(uint256 => mapping(address => bool)) alreadyVoting;

    // Winner records
    uint256[] passedContracts;

    constructor(address[11] memory _govs, uint256 _proposalLength) {
        governors = _govs;
        for (uint256 i = 0; i < governors.length; i++) {
            isGovernor[governors[i]] = true;
        }
        proposalLength = _proposalLength;
        proposalCount = 0;
    }

    function getGovernors() public view returns (address[11] memory) {
        return governors;
    }

    function createProposal(string memory userProposal)
        public
        returns (uint256)
    {
        require(isGovernor[msg.sender] == true, "not a governor");
        proposalInfo[proposalCount] = userProposal;
        isActive[proposalCount] = true;
        endContract[proposalCount] = block.timestamp + proposalLength;
        proposalCount += 1;
        return proposalCount - 1;
    }

    function voteProposal(uint256 proposalNumber) public {
        require(isGovernor[msg.sender] == true, "not a governor");
        require(isActive[proposalNumber] == true, "not an active proposal");
        require(
            alreadyVoting[proposalNumber][msg.sender] == false,
            "already voted"
        );
        alreadyVoting[proposalNumber][msg.sender] = true;
        yesVotes[proposalNumber] += 1;
    }

    function endProposal(uint256 proposalNumber) public returns (bool) {
        require(isGovernor[msg.sender] == true, "not a governor");
        require(isActive[proposalNumber] == true, "not an active proposal");
        require(
            block.timestamp >= endContract[proposalNumber],
            "proposal not ready to end"
        );
        isActive[proposalNumber] = false;

        if (yesVotes[proposalNumber] > 5) {
            passedContracts.push(proposalNumber);
            return true;
        }

        return false;
    }

    function getProposalInfo(uint256 proposalNumber)
        public
        view
        returns (string memory)
    {
        return proposalInfo[proposalNumber];
    }

    function getFinishedProposals() public view returns (uint256[] memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < passedContracts.length; i++) {
            counter += 1;
        }

        uint256[] memory passedProposals = new uint256[](counter);

        for (uint256 i = 0; i < passedProposals.length; i++) {
            passedProposals[i] = passedContracts[i];
        }

        return passedProposals;
    }
}
