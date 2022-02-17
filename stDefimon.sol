// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StDefimon is ERC721, Ownable {
    address public defimonAddress;

    constructor() ERC721("stDefimon", "SDMON") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.qzcrypt.com/";
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function setDefimonContract(address _addr) public onlyOwner {
        defimonAddress = _addr;
    }

    function issueStToken(address to, uint256 tokenId) external {
        require(msg.sender == defimonAddress, "The calling address is not authorized.");
        if(_exists(tokenId)) {
            _transfer(address(this), to, tokenId);
        } else {
            safeMint(to, tokenId);
        }

    }

    function recallStToken(address from, uint256 tokenId) external {
       require(msg.sender == defimonAddress, "The calling address is not authorized.");
       _transfer(from, address(this), tokenId); 
    }
}
