// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract NFinTech is IERC721 {
    // Note: I have declared all variables you need to complete this challenge
    string private _name;
    string private _symbol;

    uint256 private _tokenId;

    mapping(uint256 => address) private _owner;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => bool) private isClaim;
    mapping(address => mapping(address => bool)) _operatorApproval;

    error ZeroAddress();

    constructor(string memory name_, string memory symbol_) payable {
        _name = name_;
        _symbol = symbol_;
    }

    function claim() public {
        if (isClaim[msg.sender] == false) {
            uint256 id = _tokenId;
            _owner[id] = msg.sender;

            _balances[msg.sender] += 1;
            isClaim[msg.sender] = true;

            _tokenId += 1;
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owner[tokenId];
        if (owner == address(0)) revert ZeroAddress();
        return owner;
    }

    function setApprovalForAll(address operator, bool approved) external { //全部轉給別人
        // TODO: please add your implementaiton here
        
        if (operator == address(0)) revert ZeroAddress();
        _operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);

    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        // TODO: please add your implementaiton here
        
        return _operatorApproval[owner][operator];
    }

    function approve(address to, uint256 tokenId) external { //token權限轉給別人(不是全部) 注意:把token權限給別人的前提是那個token存在
        // TODO: please add your implementaiton here

        if (msg.sender != address(0)){
            address owner = ownerOf(tokenId);
            if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert ZeroAddress();
        }
        
        emit Approval(ownerOf(tokenId), to, tokenId);
        _tokenApproval[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view returns (address operator) {
        // TODO: please add your implementaiton here

        //address owner = ownerOf(tokenId); //為啥要跑這行?
        return _tokenApproval[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public { //1.擁有NFT所以可以做transfer 2.某個tokenID權限給別人所以別人可以移轉 (有token的approval) 3.全部權限給別人所以別人可以做移轉 (有那個人的approval)
        // TODO: please add your implementaiton here
        
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && msg.sender != getApproved(tokenId) && !isApprovedForAll(owner, msg.sender)) revert ZeroAddress();
        if (owner != from) revert ZeroAddress();

        if (to == address(0)) revert ZeroAddress();
        if (ownerOf(tokenId) != from) revert ZeroAddress();

        _balances[from] -= 1;
        _balances[to] += 1;
        _owner[tokenId] = to;

        emit Transfer(from, to, tokenId);
                
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public { //可以直接呼叫transferFrom，要考慮如果地址填錯怎麼辦?如填到空地址，在做token移轉時需檢查對方是否有接受這個token的能力，實作方式是做了safeTransferFrom之後，對方要回傳一個數值，然後你要去判斷那個數值對不對。
        // TODO: please add your implementaiton here
        
        transferFrom(from, to, tokenId);
        
        if (isContract(to)) {
            bytes4 result = IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data);
            if (result != bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))) {
                revert ZeroAddress();
            }
        }        
    }        
    

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // TODO: please add your implementaiton here

        transferFrom(from, to, tokenId);
        
        if (isContract(to)) {
            bytes4 result = IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "");
            if (result != bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))) {
                revert ZeroAddress();
            }
        }
    }

    
    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
      
}
