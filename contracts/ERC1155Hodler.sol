pragma solidity ^0.6.0;

import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

contract NaiveHodler {}

contract ERC1155Hodler is ERC1155Receiver {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        this.onERC1155BatchReceived.selector;
    }

function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        this.onERC1155BatchReceived.selector;
    }
}