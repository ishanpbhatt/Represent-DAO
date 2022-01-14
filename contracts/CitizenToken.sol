//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "/Users/ishan/.brownie/packages/OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC20/ERC20.sol";

contract CitizenToken is ERC20 {
    uint256 public totalAmount;
    uint256 public totalDeployed;
    address owner;

    constructor(uint256 _supply) ERC20("citizenToken", "CITZN") {
        totalAmount = _supply;
        totalDeployed = 0;
        owner = msg.sender;
    }

    function centralContractPayments(uint256 amount) public payable {
        require(msg.sender == owner, "only central contract can access this");
        _mint(owner, amount);
        totalDeployed += amount;
    }

    function getTotalAmount() public view returns (uint256, uint256) {
        return (totalDeployed, totalAmount);
    }

    // This can be customized
    function airDropTokens() public payable returns (uint256 dropCount) {
        require(this.balanceOf(msg.sender) == 0, "Non-empty balance");
        uint256 amount = 0;
        if (totalAmount * 1 > totalDeployed * 10) {
            amount = totalAmount / 1000;
            totalDeployed += amount;
        } else if (totalAmount * 2 > totalDeployed * 10) {
            amount = totalAmount / 10000;
            totalDeployed += amount;
        }
        _mint(msg.sender, amount);
        return amount;
    }
}
