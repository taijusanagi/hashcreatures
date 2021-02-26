// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract HashCreature_v1 is ERC721 {
  using SafeMath for uint256;

  event Minted(
    address indexed iss,
    uint256 indexed tokenId,
    uint256 indexed pricePaid
  );

  event Burned(
    address indexed iss,
    uint256 indexed tokenId,
    uint256 indexed priceReceived
  );

  mapping(uint256 => uint256) public transferCount;
  mapping(uint256 => bytes32) public hashMemory;

  uint256 public constant initMintPrice = 0.001 ether;
  uint256 public constant initBurnPrice = 0.0009 ether;

  string public name;
  string public symbol;
  uint256 public nonce;
  uint256 public supplyLimit;
  uint256 public totalSupply;
  address payable public creator;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supplyLimit,
    address payable _creator
  ) public {
    name = _name;
    symbol = _symbol;
    supplyLimit = _supplyLimit;
    creator = _creator;
  }

  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    transferCount[tokenId]++;
    super._transferFrom(from, to, tokenId);
  }

  function changeCreator(address payable _creator) public {
    require(creator == msg.sender, "msg.sender must be current creator");
    creator = _creator;
  }

  function mint() external payable {
    require(
      totalSupply < supplyLimit,
      "total supply must be less than max supply"
    );
    uint256 mintPrice = getPriceToMint(totalSupply);
    require(msg.value >= mintPrice, "msg.value must be grater than mint price");
    uint256 reserveCut = getPriceToBurn(totalSupply);
    nonce = nonce.add(1);
    totalSupply = totalSupply.add(1);
    bytes32 hash =
      keccak256(
        abi.encodePacked(
          block.number,
          blockhash(block.number - 1),
          getChainId(),
          address(this),
          msg.sender,
          nonce
        )
      );
    hashMemory[nonce] = hash;
    _mint(msg.sender, nonce);
    creator.transfer(mintPrice.sub(reserveCut));
    if (msg.value.sub(mintPrice) > 0) {
      msg.sender.transfer(msg.value.sub(mintPrice));
    }
    emit Minted(msg.sender, nonce, mintPrice);
  }

  function burn(uint256 tokenId) public {
    uint256 burnPrice = getPriceToBurn(totalSupply);
    _burn(msg.sender, tokenId);
    totalSupply = totalSupply.sub(1);
    msg.sender.transfer(burnPrice);
    emit Burned(msg.sender, tokenId, burnPrice);
  }

  function getPriceToMint(uint256 _supply) public view returns (uint256) {
    require(_supply < supplyLimit, "supply must be less than max supply");
    return initMintPrice.add(_supply.mul(initMintPrice));
  }

  function getPriceToBurn(uint256 _supply) public view returns (uint256) {
    require(_supply < supplyLimit, "supply must be less than max supply");
    return _supply.mul(initBurnPrice);
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

  function getImageData(bytes32 hash, uint256 transferCount)
    public
    view
    returns (string memory)
  {
    string memory color =
      string(
        abi.encodePacked(
          "hsl(",
          uintToString(uint256(hash) % 360),
          ", ",
          uintToString(transferCount <= 100 ? 100 - transferCount : 0),
          "%, 50%)"
        )
      );
    uint256 canvasSize = 360;
    uint256 cellSize = 45;
    bytes memory temp;
    for (uint256 i = 0; i < hash.length; i++) {
      uint8 num = uint8(hash[i]) % 2;
      uint8 x = uint8(i % 4);
      uint8 y = uint8(i / 4);
      temp = abi.encodePacked(
        temp,
        '<rect x=\\"',
        uintToString(x * cellSize),
        '\\" y=\\"',
        uintToString(y * cellSize),
        '\\" width=\\"45\\" height=\\"45\\" style=\\"fill:',
        num == 0 ? color : "white",
        ';stroke-width:1;\\"></rect>',
        '<rect x=\\"',
        uintToString((7 - x) * cellSize),
        '\\" y=\\"',
        uintToString(y * cellSize),
        '\\" width=\\"45\\" height=\\"45\\" style=\\"fill:',
        num == 0 ? color : "white",
        ';stroke-width:1;\\"></rect>'
      );
    }
    return
      string(
        abi.encodePacked(
          '<svg xmlns=\\"http://www.w3.org/2000/svg\\" id=\\"svgcanvas\\" width=\\"',
          uintToString(canvasSize),
          '\\" height=\\"',
          uintToString(canvasSize),
          '\\">',
          temp,
          "</svg>"
        )
      );
  }

  function getMetaData(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "token must exist");
    return
      string(
        abi.encodePacked(
          '{"image_data":"',
          getImageData(hashMemory[tokenId], transferCount[tokenId]),
          '","name":"',
          name,
          "#",
          uintToString(tokenId),
          '"}'
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
