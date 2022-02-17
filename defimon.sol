// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface StDefimon {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function issueStToken(address to, uint256 tokenId) external;
    function recallStToken(address from, uint256 tokenId) external;
}

interface Defigenetics { 
    struct DefimonStats {
        uint256 geneId;
	    uint256 healthPoints;
	    uint256 attack;
	    uint256 defence;
	    uint256 specialAttack;
	    uint256 specialDefence;
	    uint256 specialEvade;
	}

    function generateStats(uint256 _tokenId) external returns (DefimonStats memory);
}

contract DefiMon is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 constant public MINTING_PRICE = 0.03 ether;
	uint256 constant public HATCHING_PRICE = 0.01 ether;
    uint256 constant public MAX_MINT_EGGS = 10000;
    string public EGG_URI;
    string public URI;
    bool public saleIsActive = false;
    bool public hatchingIsActive = false;

    Defigenetics public defigenetics;
    StDefimon public stDefimon;
    mapping(uint256 => DefimonStats) public tokenIdToDefimonStats;
    mapping(uint256 => bool) isHatched;

    mapping(uint256 => uint256) stakingTimestamp;

    uint256 public baseStakingRewards = 100;
    mapping(address => uint256) public claimedRewards;

    address public tokenContractAddress;
 
    struct DefimonStats {
        uint256 geneId;
	    uint256 healthPoints;
	    uint256 attack;
	    uint256 defence;
	    uint256 specialAttack;
	    uint256 specialDefence;
	    uint256 specialEvade;
        uint256 generation;
        uint256 birthTime;
        uint256 XP;
        uint256 level;
	}    
    
   constructor() ERC721("Defimon", "DMON") { }

    function setStatsContractAddress(address _addr) external {
        defigenetics = Defigenetics(_addr);
    } 

    function setStDefimonAddress(address _addr) external {
        stDefimon = StDefimon(_addr);
    } 

    function hatchEgg(uint256 _tokenId) public {
        require(_exists(_tokenId),"This token Id has not been minted");
        require(hatchingIsActive, "Hatching is not Active");
        require(!isHatched[_tokenId], "Egg already hatched");
        DefimonStats storage baseStats = tokenIdToDefimonStats[_tokenId];
        Defigenetics.DefimonStats memory tempBaseStats;      
        tempBaseStats = defigenetics.generateStats(_tokenId);
        baseStats.geneId = tempBaseStats.geneId;
        baseStats.healthPoints = tempBaseStats.healthPoints;
        baseStats.attack = tempBaseStats.attack;
        baseStats.defence = tempBaseStats.defence;
        baseStats.specialAttack = tempBaseStats.specialAttack;
        baseStats.specialDefence = tempBaseStats.specialDefence;
        baseStats.specialEvade = tempBaseStats.specialEvade;
        baseStats.generation = 0;
        baseStats.birthTime = block.timestamp;
        baseStats.XP = 0;
        baseStats.level = 0;
        _setTokenURI(_tokenId, string(abi.encodePacked(URI, _tokenId.toString())));
        isHatched[_tokenId] = true;
    }

    function hatchEggPaid(uint256 _tokenId) public payable {
        require(_exists(_tokenId),"This token Id has not been minted");
        require(msg.value == HATCHING_PRICE, "Price sent is not correct");
        require(!isHatched[_tokenId], "Egg already hatched");
        DefimonStats storage baseStats = tokenIdToDefimonStats[_tokenId];
        Defigenetics.DefimonStats memory tempBaseStats;      
        tempBaseStats = defigenetics.generateStats(_tokenId);
        baseStats.geneId = tempBaseStats.geneId;
        baseStats.healthPoints = tempBaseStats.healthPoints;
        baseStats.attack = tempBaseStats.attack;
        baseStats.defence = tempBaseStats.defence;
        baseStats.specialAttack = tempBaseStats.specialAttack;
        baseStats.specialDefence = tempBaseStats.specialDefence;
        baseStats.specialEvade = tempBaseStats.specialEvade;
        baseStats.generation = 0;
        baseStats.birthTime = block.timestamp;
        baseStats.XP = 0;
        baseStats.level = 0;
        isHatched[_tokenId] = true;
    }
    
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    // withdraws the funds held by contract to contract owner's address
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // toggle sale status to allow/disallow minting NFTs
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // toggle sale status to allow/disallow hatching NFTs
    function flipHatchingState() public onlyOwner {
        hatchingIsActive = !hatchingIsActive;
    }
  
    function mintEgg(uint numberOfTokens) public payable{
        require(saleIsActive, "Sale must be active to mint Eggs");
        require(msg.value == MINTING_PRICE.mul(numberOfTokens), "Payable value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_MINT_EGGS) {               
                _safeMint(msg.sender, tokenId);
                _setTokenURI(tokenId, string(abi.encodePacked(EGG_URI, tokenId.toString())));
                _tokenIdCounter.increment();
            } else {
                saleIsActive = !saleIsActive;
                payable(msg.sender).transfer(numberOfTokens.sub(i).mul(MINTING_PRICE));
                break;
            }
        }
    }
		
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
    
    function setEggURI(string memory _EGG_URI) public onlyOwner {
        EGG_URI = _EGG_URI;
    }

    function setCommonURI(string memory _URI) public onlyOwner {
        URI = _URI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    function stakeDefimon(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId),"Caller is not the owner of NFT");
        safeTransferFrom(msg.sender, address(this), _tokenId);
        stDefimon.issueStToken(msg.sender, _tokenId);
        stakingTimestamp[_tokenId] = block.timestamp;
    }

    function unStakeDefimon(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == address(this),"NFT is not staked");
        require(msg.sender == stDefimon.ownerOf(_tokenId),"NFT is not staked by this address");
        claimStakingRewards(_tokenId);
        stDefimon.recallStToken(msg.sender, _tokenId);        
        _transfer(address(this), msg.sender, _tokenId);
        stakingTimestamp[_tokenId] = 0;
    }

    function stakingRewards(uint256 _tokenId) public view returns(uint256) {
        require(ownerOf(_tokenId) == address(this),"NFT is not staked");
        //hourly distribution set - division by 3600
        uint256 currentRewards = (block.timestamp - stakingTimestamp[_tokenId])/3600 * baseStakingRewards;
        return currentRewards;
    }

    function claimStakingRewards(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == address(this),"NFT is not staked");
        require(msg.sender == stDefimon.ownerOf(_tokenId),"NFT is not staked by this address");
        uint256 currentRewards = stakingRewards(_tokenId);
        claimedRewards[msg.sender] = claimedRewards[msg.sender] + currentRewards;
        stakingTimestamp[_tokenId] = block.timestamp;
    }

    function setStakingRewards(uint256 _baseRewards) public onlyOwner {
        baseStakingRewards = _baseRewards;
    }

    function withdrawStakingRewards(address _stakingAddress) external {
        require(msg.sender == tokenContractAddress, "Function call is not authorized from this address");
        require(claimedRewards[_stakingAddress] != 0, "No rewards for this address");
        claimedRewards[_stakingAddress] = 0;
    }

    function setTokenAddress(address _contractAddress) public onlyOwner {
        tokenContractAddress = _contractAddress;
    }

}