# Represent-DAO
DAO governance protocol that relies on representative governance


### RepresentDAO

- Central Smart Contract
- Holds election lengths + governor terms
- Election Factory
    - Starts and ends elections using instances of the  GovernorVoting contract
    - Returns the list of governors and the voting constituencies associated with them
    - Can be started and ended by anyone as long as it fulfills the time constraints of an election term
- Governor Proposal Factory
    - Generated at the end of every election
    - Given token awards for winning governors
- Citizen and Constituent Impeachment Factories
    - Generates contract that returns bool
    - If impeachment successful, then special election occurs
    - Governor is removed instantly
- Special Election Factory
    - Starts and ends using SpecialElection contract, replaces the current governor that was impeached

### GovernorVoting

- Registration to be able to vote
    - Given token awards for registration
- Nominations to “ballot” citizens
- Vote function for balloted citizens
- Declare winners and constituents

### GovernorProposals

- Time period for each proposal
- Needs simple majority to pass

### CitizenImpeachment / ConstituentImpeachment

- Registration to be able to vote
    - Given token awards for registration
- Majority to impeach
- End Election at a given time

### CitizenToken

- Airdrop tokens at decreasing rate up to some value
- Give access to central contract to distribute rewards
