// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/access/AccessControlEnumerable.sol";

contract Voting is AccessControlEnumerable{

    event NewVote(uint indexed proposalId, address indexed voter, uint voteCount);

    struct Voter {
        bool voted;
        address delegate;
        uint weight;
        uint vote;
    }

    struct Proposal {
        string name;
        uint voteCount;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You are not administrator");
        _;
    }

    modifier hasAlreadyVoted() {
        require(!voters[msg.sender].voted, "The voter has already voted.");
        _;
    }

    modifier hasRightToVote() {
        require(voters[msg.sender].weight>0, "The vote has no right to vote.");
        _;
    }

    address public creator;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(string[] memory proposalNames) {
        require(proposalNames.length>1, "You need at least 2 proposalName");
        creator = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
            name: proposalNames[i],
            voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public isAdmin{
        require(!voters[voter].voted, "The voter has already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) public hasAlreadyVoted {
        require(to != msg.sender, "Self-delegation is disallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "You can't delegete vote to eachother.");
        }
        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposalId) public hasAlreadyVoted hasRightToVote {
        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.vote = proposalId;

        proposals[proposalId].voteCount += sender.weight;
        emit NewVote(proposalId, msg.sender,proposals[proposalId].voteCount);
    }


    function getWinnerId() public view returns (uint winnerId_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winnerId_ = p;
            }
        }
    }

    function getWinnerName() public view returns (string memory winnerName_) {
        winnerName_ = proposals[getWinnerId()].name;
    }
}