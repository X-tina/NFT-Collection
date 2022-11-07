// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
  string _baseTokenURI;
  uint256 public _price = 0.01 ether;
  // _paused is used to pause the contract in case of an emergency
  bool public _paused;
  // max number of CryptoDevs
  uint256 public maxTokenIds = 20;
  // total number of tokenIds minted
  uint256 public tokenIds;
  // Whitelist contract instance
  IWhitelist whitelist;
  // timestamps..
  bool public presaleStarted;
  uint256 public presaleEnded;

  modifier onlyWhenNotPaused {
    require(!_paused, 'Contract currently paused');
    _;
  }

  constructor(string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
    _baseTokenURI = baseURI;
    whitelist = IWhitelist(whitelistContract);
  }

  function startPresale() public onlyOwner {
    require(!presaleStarted, 'Already started');

    presaleStarted = true;
    presaleEnded = block.timestamp + 5 minutes;
  }

  /**
  * @dev presaleMint allows a user to mint one NFT per transaction during the presale.
  */
  function presaleMint() public payable onlyWhenNotPaused {
    require(presaleStarted && block.timestamp < presaleEnded, 'Presale is not running');
    require(whitelist.whiteListedAddresses(msg.sender), 'You are not whitelisted');
    require(tokenIds < maxTokenIds, 'Exceeded maximum Crypto Devs supply');
    console.log('value = ', msg.value);
    require(msg.value >= _price, 'Ether sent is not correct');

    tokenIds += 1;
    //_safeMint is a safer version of the _mint function as it ensures that
    // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
    // If the address being minted to is not a contract, it works the same way as _mint
    _safeMint(msg.sender, tokenIds);
  }

  /**
  * @dev mint allows a user to mint 1 NFT per transaction after the presale has ended.
  */
  function mint() public payable onlyWhenNotPaused {
    require(presaleStarted && block.timestamp >=  presaleEnded, 'Presale has not ended yet');
    require(tokenIds < maxTokenIds, 'Exceed maximum Crypto Devs supply');
    require(msg.value >= _price, 'Ether sent is not correct');

    tokenIds += 1;
    _safeMint(msg.sender, tokenIds);
  }

  /**
  * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
  * returned an empty string for the baseURI
  */
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  /**
  * @dev setPaused makes the contract paused or unpaused
  */
  function setPaused(bool val) public onlyOwner {
    _paused = val;
  }

  /**
  * @dev withdraw sends all the ether in the contract
  * to the owner of the contract
  */
  function withdraw() public onlyOwner {
    address _owner = owner();
    uint256 amount = address(this).balance;
    (bool sent, ) = _owner.call{value: amount}("");

    require(sent, 'Failed to send Ether');
  }
  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
}