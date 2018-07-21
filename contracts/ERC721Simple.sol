pragma solidity ^0.4.24;

import "./utl/SafeMath.sol";


  	/**
	 * @title  A simple implementation of the ERC721 Non-Fungible Token Standard	 * 
	 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
	 * modified from https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/token/ERC721
	 * and from https://github.com/1000ethhomepage/1000ethhomepage-contracts
	 */


contract ERC721Simple {    

    using SafeMath for uint256;	

    // -----------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Variables ------------------------------------------------
    // ----------------------------------------------------------------------------------------------------------- 

    uint256 public totalSupply;	

    // Basic references
	//Mapping from token ID to owner address
    mapping(uint256 => address) internal tokenIdToOwner;	
	
	 // Mapping from owner to list of owned token IDs
    mapping(address => uint[]) internal listOfOwnerTokens;
	
	// Mapping from token ID to index of the owner tokens list	
    mapping(uint256 => uint256) internal tokenIndexInOwnerArray;	
	
    // Mapping from token ID to address approved to transfer the token
    mapping(uint256 => address) internal approvedAddressToTransferTokenId;	

    // -----------------------------------------------------------------------------------------------------------
    // -------------------------------------------------- Events -------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // -----------------------------------------------------------------------------------------------------------
    // -------------------------------------------------- Modifiers ----------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    modifier onlyExtantToken(uint256 _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    // -----------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ View functions -------------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    /// @dev Returns the address currently marked as the owner of _tokenID. 
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

    /// @dev Get the total supply of token held by this contract. 
    function totalSupply() public view returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

    /// @dev Gets the balance of the specified address
    function balanceOf(address _owner) public view returns (uint256 _balance)
    {
        return listOfOwnerTokens[_owner].length;
    }

    /// @dev Gets the approved address to take ownership of a given token ID
    function approvedFor(uint256 _tokenId) public view returns (address _approved)
    {
        return approvedAddressToTransferTokenId[_tokenId];
    }

    /// @dev Gets the list of tokens owned by a given address
    function tokensOf(address _owner) public view returns (uint256[]) {
        return listOfOwnerTokens[_owner];
    }

    // -----------------------------------------------------------------------------------------------------------
    // --------------------------------------------- Core Public functions ---------------------------------------
    // -----------------------------------------------------------------------------------------------------------

	/// @dev Assigns the ownership of the NFT with ID _tokenId to _to
    function transfer(address _to, uint256 _tokenId) public onlyExtantToken (_tokenId) onlyOwnerOfToken (_tokenId)
    {
        require(_to != address(0)); 

        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Grants approval for address _to to transfer the NFT with ID _tokenId.
    function approve(address _to, uint256 _tokenId) public onlyExtantToken(_tokenId) onlyOwnerOfToken (_tokenId)
    {
        require(msg.sender != _to);
        require(_to != address(0));

        approvedAddressToTransferTokenId[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);  
    }

    /// @dev Remove approval for address _to to transfer the NFT with ID _tokenId.
    function removeApproval (uint256 _tokenId) public onlyExtantToken (_tokenId)  onlyOwnerOfToken (_tokenId) {
        require(approvedAddressToTransferTokenId[_tokenId] != address(0));
        _clearTokenApproval(_tokenId);
        emit Approval(msg.sender, address(0), _tokenId);
    }

    /// @dev transfer token From owner to _to
    function transferFrom(address _to, uint256 _tokenId) public onlyExtantToken(_tokenId)
    {
        require(approvedAddressToTransferTokenId[_tokenId] == msg.sender);
        require(_to != address(0));

        emit Transfer(ownerOf(_tokenId), _to, _tokenId);

        _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);     
    }

    // -----------------------------------------------------------------------------------------------------------
    // ----------------------------------------------- Internal functions ----------------------------------------
    // -----------------------------------------------------------------------------------------------------------

    // set the new token owner
    function _setTokenOwner(uint256 _tokenId, address _owner) internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    // add a token to the new owner list
    function _addTokenToOwnersList(address _owner, uint256 _tokenId) internal
    {
        listOfOwnerTokens[_owner].push(_tokenId);
        tokenIndexInOwnerArray[_tokenId] = listOfOwnerTokens[_owner].length.sub(1);
    }

    // remove token for the last owner list 
    function _removeTokenFromOwnersList(address _owner, uint256 _tokenId) internal
    {
        uint256 length = listOfOwnerTokens[_owner].length; // length of owner tokens
        uint256 index = tokenIndexInOwnerArray[_tokenId]; // index of token in owner array
        uint256 swapToken = listOfOwnerTokens[_owner][length - 1]; // last token in array

        listOfOwnerTokens[_owner][index] = swapToken; // last token pushed to the place of the one that was transfered
        tokenIndexInOwnerArray[swapToken] = index; // update the index of the token we moved

        delete listOfOwnerTokens[_owner][length - 1]; // remove the case we emptied
        listOfOwnerTokens[_owner].length--; // shorten the array's length
    }

    // when the token move from one user to another, we clear the approval made by the last owner
    function _clearTokenApproval(uint256 _tokenId) internal
    {
        approvedAddressToTransferTokenId[_tokenId] = address(0);
    }

    // calls all the internal functions above, to transfer a token from one user to another
    function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }
}