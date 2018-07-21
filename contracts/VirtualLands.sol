pragma solidity ^0.4.24;

import "./ERC721Simple.sol";

  	/**
	 * @title VitualLands of Shangeri-La
	 *
	 * A script that manages 10 000 tokens that represents a piece of vitual land within Shangeri-La.
	 */

contract  VirtualLands is ERC721Simple {

    // -----------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Variables ------------------------------------------------
    // ----------------------------------------------------------------------------------------------------------- 

    string public name = "VirtualLands";
    string public symbol = "VLs";
	
	// the one who deployed the smart contract
    address public owner;	
	
	// the limit of totalSupply of tokens representing vituallands.
    uint256 public totalSupplyLimit;
	
	// the price in wei, for the initial sale of virtuallands
    uint256 public initialPrice;
	
	// white for "not owned by anyone" ,  green for "owned", blue for "owned and for sale".
    mapping(uint => string) public tokenToPixelsColors;  
	
	// A string set and modified by land owner.
    mapping(uint => string) public tokenToDescription;
	
	// A link set by owner to the description of his land;
    mapping(uint => string) public tokenToLink;  

    // The ether balance of all users of the smart contract
    mapping(address => uint) public BalanceOfEther;
	
	// if equals zero, it's not up for sale
    mapping(uint => uint) public tokenToSalePrice; 

    // -----------------------------------------------------------------------------------------------------------
    // -------------------------------------------------- Events -------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    event EmitUpForSale(uint256 _tokenId, uint256 _price);
    event EmitBought(uint256 _tokenId, uint256 _at, address _by);
    event EmitSaleOfferRemoved(uint256 _tokenId);
    event EmitSetInitialPrice(uint256 _initialPrice);
    event EmitChangedPixelsColors(uint256 _tokenId);    
    event EmitChangedDescription(uint256 _tokenId);
    event EmitChangedLink(uint256 _tokenId);

    // -----------------------------------------------------------------------------------------------------------
    // -------------------------------------------------- Modifiers ----------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner permitted to call");
        _;
    }
    
    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }

    modifier isUpForSale(uint _tokenId) {
        require(tokenToSalePrice[_tokenId] > 0);
        _;
    }

    modifier isNotUpForSale(uint _tokenId) {
        require(tokenToSalePrice[_tokenId] == 0);
        _;
    }

    modifier onlyNotOwnerOfToken(uint _tokenId) {
        require(ownerOf(_tokenId) != msg.sender);
        _;
    }

    // -----------------------------------------------------------------------------------------------------------
    // ------------------------------------------------- Constructor ---------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    constructor () public {
        owner = msg.sender;
        totalSupplyLimit = 10000;
        initialPrice = 10000000000000000;  //  0.01 eth = 10 finney
    }

    // -----------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ View functions -------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    /// @dev Gets the total supply limit of the virtual land tokens
    function totalSupplyLimit() public view returns (uint256) {
        return totalSupplyLimit;
    }

    /// @dev Gets the price for initial supply of virtual lands
    function initialPrice() public view returns (uint256) {
        return initialPrice;
    }

    // -----------------------------------------------------------------------------------------------------------
    // --------------------------------------------- Core Public functions ---------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    /// @dev Initial acquisition of the token
    function initialBuyToken (uint _tokenId) payable public onlyNonexistentToken (_tokenId) {
        
        require(msg.value == initialPrice, "value sent must be exactly equals to price");  
        require(_tokenId <= totalSupplyLimit);

        BalanceOfEther[owner] += msg.value;

        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);

        totalSupply += 1;

        emit EmitBought(_tokenId, msg.value, msg.sender);
    }
	
	/// @dev changing the initialprice for sale, can only be called by owner
    /// @notice the _initialPrice is in Wei
    function setInitialPrice (uint _initialPrice) public onlyOwner() {
        initialPrice = _initialPrice;
        emit EmitSetInitialPrice(_initialPrice);
    }

    /// @dev changing the description of the token
    function setTokenDescription (uint _tokenId, string _newDescription) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId) {
        tokenToDescription[_tokenId] = _newDescription;
        emit EmitChangedDescription(_tokenId);
    }

    /// @dev changing the link of the token
    function setTokenLink (uint _tokenId, string _newLink) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId) {
        tokenToLink[_tokenId] = _newLink;
        emit EmitChangedLink(_tokenId);
    }

    /// @dev withdraw ether off the contract
    function withdraw() public
    {
        uint amount = BalanceOfEther[msg.sender];
        BalanceOfEther[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    /// @dev putting token up for sale
    /// @notice the _price is in Wei
    function sellToken (uint _tokenId, uint _price) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId) isNotUpForSale(_tokenId) {
        require(_price > 0);

        tokenToSalePrice[_tokenId] = _price;

        emit EmitUpForSale(_tokenId, _price);
    }

    /// @dev buying token from someone
    function buyToken (uint _tokenId) payable public onlyExtantToken (_tokenId) isUpForSale (_tokenId) onlyNotOwnerOfToken (_tokenId) {
        require(msg.value >= tokenToSalePrice[_tokenId]);

        tokenToSalePrice[_tokenId] = 0;
        BalanceOfEther[ownerOf(_tokenId)] = msg.value.sub(1000000000000000); // substracts 1 finney 
        BalanceOfEther[owner] = BalanceOfEther[owner].add(1000000000000000); // transfer fee to owner
        _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);

        emit EmitBought(_tokenId, msg.value, msg.sender);
    }

    /// @dev removing a sale proposition
    function removeTokenFromSale (uint _tokenId) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId) isUpForSale (_tokenId) {
        tokenToSalePrice[_tokenId] = 0;
        emit EmitSaleOfferRemoved(_tokenId);
    }

    /// @dev changing the colors of the token
    function setTokenPixelsColors (uint _tokenId, string _newColors) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId) {
        tokenToPixelsColors[_tokenId] = _newColors;
        emit EmitChangedPixelsColors(_tokenId);
    }

    // -----------------------------------------------------------------------------------------------------------
    // ----------------------------------------------- Internal functions ----------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    // calls all the internal functions above, to transfer a token from one user to another
    // changed to nullify the selling offer when a token changes hands
    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId) internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);

        tokenToSalePrice[_tokenId] = 0;

        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }
}