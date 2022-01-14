//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "/Users/ishan/.brownie/packages/OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC20/ERC20.sol";
import "./GovernorVoting.sol";
import "./GovernorProposal.sol";
import "./CitizenToken.sol";
import "./Impeachment.sol";

contract RepresentDAO {
    // Tokens
    CitizenToken citizenToken;

    // Elections
    uint256 startTime = 0;
    uint256 endTime = 0;
    bool isElection = false;

    GovernorVoting governorElection;
    uint256 electionDuration;
    uint256 electionTerm;
    uint256 nominationCost;

    // Governance
    GovernorProposal proposalContract;
    string[] passedProposals;
    uint256 winnerRewards;
    uint256 proposalLength;

    // Reward Systems, TODO

    // Impeachment, TODO: specicial eletion after impeachment
    Impeachment impeachContract;
    bool isImpeachment = false;
    uint256 impeachmentDuration;
    uint256 impeachmentStart = 0;

    constructor(
        uint256 _electionDuration,
        uint256 _electionTerm,
        uint256 _impeachmentDuration,
        uint256 _proposalLength,
        uint256 _tokenSupply,
        uint256 _winnerRewards
    ) {
        citizenToken = new CitizenToken(_tokenSupply);
        electionDuration = _electionDuration;
        electionTerm = _electionTerm;
        winnerRewards = _winnerRewards;
        impeachmentDuration = _impeachmentDuration;
        proposalLength = _proposalLength;
    }

    // Returns address of governor token
    function getGovToken() public view returns (address) {
        return address(citizenToken);
    }

    // Starts election for new election
    function startElection() public returns (address) {
        require(
            citizenToken.balanceOf(msg.sender) > 0,
            "Only citizens can start an election"
        );
        require(
            block.timestamp > endTime + electionTerm,
            "Not valid election start date"
        );
        require(isElection == false, "There is an active election");
        isElection = true;
        startTime = block.timestamp;
        endTime = block.timestamp + electionDuration;
        governorElection = new GovernorVoting(nominationCost, citizenToken);
        return address(governorElection);
    }

    // Declares winners, constituencies + government proposal factory
    function endElection() public returns (address[11] memory) {
        require(
            citizenToken.balanceOf(msg.sender) > 0,
            "this function can only be used by citizens"
        );
        require(isElection == true, "No election to end");
        require(block.timestamp > endTime, "Election is still going");

        isElection = false;
        address[11] memory newGovernors = governorElection.declare();

        _payoutRewardsElect(newGovernors); // NEEDS TO GET UPDATED
        _updateProposals();
        proposalContract = new GovernorProposal(newGovernors, proposalLength);

        return newGovernors;
    }

    // Temporary election rewards mechanism
    function _payoutRewardsElect(address[11] memory governors) private {
        for (uint256 i = 0; i < 11; i++) {
            address winner = governors[i];
            citizenToken.centralContractPayments(winnerRewards);
            citizenToken.transfer(winner, winnerRewards);

            address[] memory constituents;
            uint256[] memory votes;
            uint256 totalVotes;
            (constituents, votes, totalVotes) = governorElection
                .getConstituency(winner);
            citizenToken.centralContractPayments(winnerRewards);
            for (uint256 j = 0; j < votes.length; j++) {
                uint256 distAmount = (winnerRewards * votes[j]) / totalVotes;
                citizenToken.transfer(constituents[j], distAmount);
            }
        }
    }

    function _updateProposals() private {
        if (address(proposalContract) != address(0)) {
            uint256[] memory proposalNums = proposalContract
                .getFinishedProposals();

            string memory proposalInfo;
            for (uint256 i = 0; i < proposalNums.length; i++) {
                proposalInfo = proposalContract.getProposalInfo(
                    proposalNums[i]
                );
                passedProposals.push(proposalInfo);
            }
        }
    }

    // Getter function to return passed proposals
    function getProposals() public view returns (string[] memory) {
        uint256 passedLength = 0;
        for (uint256 i = 0; i < passedProposals.length; i++) {
            passedLength += 1;
        }

        string[] memory proposals = new string[](passedLength);
        for (uint256 i = 0; i < passedProposals.length; i++) {
            proposals[i] = passedProposals[i];
        }
        return proposals;
    }

    function startImpeachment(address governor) public returns (address) {
        require(
            citizenToken.balanceOf(msg.sender) > 0,
            "this function can only be used by citizens"
        );
        require(isImpeachment == false, "there is an active impeachment");
        impeachContract = new Impeachment(
            governor,
            address(this),
            citizenToken
        );
        isImpeachment = true;
        impeachmentStart = block.timestamp;
        return address(impeachContract);
    }

    // End impeachment vote, if pass launch new proposal contract without current governor
    // TODO: Special Election
    function endImpeachment() public returns (bool) {
        require(
            citizenToken.balanceOf(msg.sender) > 0,
            "Only citizens can end impeachments"
        );
        require(isImpeachment == true, "There is no active impeachment");
        require(
            impeachmentStart + impeachmentDuration <= block.timestamp,
            "Impeachment duration is not done"
        );
        (bool isPassed, uint256 yesVotes, uint256 totalVotes) = impeachContract
            .poll();

        if (isPassed == true) {
            address impeachedGovernor = impeachContract.getGovernor();
            address[11] memory oldGovernors = proposalContract.getGovernors();

            for (uint256 i = 0; i < 11; i++) {
                if (oldGovernors[i] == impeachedGovernor) {
                    oldGovernors[i] = address(0);
                }
            }
            proposalContract = new GovernorProposal(
                oldGovernors,
                proposalLength
            );
        }
        impeachContract.redistribute();
        return isPassed;
    }
}
