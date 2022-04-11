pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    uint256 intialsupply;

    constructor(
        string memory name,
        string memory symbol,
        uint256 intialsupply
    ) public ERC20(name, symbol) {
        // 1 dollar = 100 cents i.e 1 token = 1 * (10 ** decimals)
        // _mint(msg.sender, 100 * 10**uint(decimals()));
        _mint(msg.sender, intialsupply);
    }
}
