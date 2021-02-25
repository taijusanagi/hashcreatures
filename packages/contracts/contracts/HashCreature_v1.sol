// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract HashCreature_v1 is ERC721 {
  mapping(uint256 => uint256) public blockNumberMemory;
  mapping(uint256 => bytes32) public lastBlockHashMemory;
  mapping(uint256 => bytes32) public nameMemory;
  mapping(uint256 => address) public issMemory;

  string public name;
  string public symbol;

  uint256 public totalSupply;
  uint256 public maxSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply
  ) public {
    name = _name;
    symbol = _symbol;
    maxSupply = _maxSupply;
  }

  function mint(bytes32 _name) external {
    require(
      totalSupply < maxSupply,
      "total supply must be less than max supply"
    );
    totalSupply++;
    blockNumberMemory[totalSupply] = block.number;
    lastBlockHashMemory[totalSupply] = blockhash(block.number - 1);
    nameMemory[totalSupply] = _name;
    issMemory[totalSupply] = msg.sender;
    _mint(msg.sender, totalSupply);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "token must exist");
    return
      string(
        abi.encodePacked("ipfs://", getCidFromString(getMetaData(tokenId)))
      );
  }

  function getChainId() public pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function getCidFromString(string memory input)
    public
    view
    returns (string memory)
  {
    return
      string(
        _bytesToBase58(
          addSha256FunctionCodePrefix(
            bytesToIpfsDigest(abi.encodePacked(input))
          )
        )
      );
  }

  function getImageData(bytes32 hash) public view returns (string memory) {
    for (uint256 i = 0; i < hash.length; i++) {
      console.log(uint8(hash[i]) % 2);
    }
    //image generation goes here
    return "<svg>";
  }

  function getMetaData(uint256 tokenId) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"blockNumber":"',
          uintToString(blockNumberMemory[tokenId]),
          '","lastBlockHash":"',
          bytesToString(abi.encodePacked(lastBlockHashMemory[tokenId])),
          '","chainId":"',
          uintToString(getChainId()),
          '","contractAddress":"',
          bytesToString(abi.encodePacked(address(this))),
          '","tokenId":"',
          uintToString(tokenId),
          '","iss":"',
          bytesToString(abi.encodePacked(issMemory[tokenId])),
          '","name":"',
          bytes32ToString(nameMemory[tokenId]),
          '","image_data":"',
          getImageData(getSeedHash(tokenId)),
          '"}'
        )
      );
  }

  function getSeedHash(uint256 tokenId) public view returns (bytes32) {
    require(_exists(tokenId), "token must exist");

    return
      keccak256(
        abi.encodePacked(
          blockNumberMemory[tokenId],
          lastBlockHashMemory[tokenId],
          getChainId(),
          address(this),
          tokenId,
          issMemory[tokenId],
          nameMemory[tokenId]
        )
      );
  }

  function bytesToIpfsDigest(bytes memory input)
    private
    view
    returns (bytes32)
  {
    bytes memory len = lengthEncode(input.length);
    bytes memory len2 = lengthEncode(input.length + 4 + 2 * len.length);
    return
      sha256(
        abi.encodePacked(hex"0a", len2, hex"080212", len, input, hex"18", len)
      );
  }

  function lengthEncode(uint256 length) private view returns (bytes memory) {
    if (length < 128) {
      return uintToBinary(length);
    } else {
      return
        abi.encodePacked(
          uintToBinary((length % 128) + 128),
          uintToBinary(length / 128)
        );
    }
  }

  function uintToBinary(uint256 x) private view returns (bytes memory) {
    if (x == 0) {
      return new bytes(0);
    } else {
      bytes1 s = bytes1(uint8(x % 256));
      bytes memory r = new bytes(1);
      r[0] = s;
      return abi.encodePacked(uintToBinary(x / 256), r);
    }
  }

  function addSha256FunctionCodePrefix(bytes32 input)
    private
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(hex"1220", input);
  }

  function bytes32ToString(bytes32 _bytes32)
    private
    pure
    returns (string memory)
  {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function _bytesToBase58(bytes memory input)
    private
    pure
    returns (bytes memory)
  {
    bytes memory alphabet =
      "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    uint8[] memory digits = new uint8[](46);
    bytes memory output = new bytes(46);
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i < input.length; ++i) {
      uint256 carry = uint8(input[i]);
      for (uint256 j = 0; j < digitlength; ++j) {
        carry += uint256(digits[j]) * 256;
        digits[j] = uint8(carry % 58);
        carry = carry / 58;
      }
      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        digitlength++;
        carry = carry / 58;
      }
    }
    for (uint256 k = 0; k < digitlength; k++) {
      output[k] = alphabet[digits[digitlength - 1 - k]];
    }
    return output;
  }

  function bytesToString(bytes memory input)
    private
    pure
    returns (string memory)
  {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory output = new bytes(2 + input.length * 2);
    output[0] = "0";
    output[1] = "x";
    for (uint256 i = 0; i < input.length; i++) {
      output[2 + i * 2] = alphabet[uint256(uint8(input[i] >> 4))];
      output[3 + i * 2] = alphabet[uint256(uint8(input[i] & 0x0f))];
    }
    return string(output);
  }

  function uintToString(uint256 value) private pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}
