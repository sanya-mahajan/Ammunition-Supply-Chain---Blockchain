// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AmmunitionSupplyChain is ERC721("Ammunition Supply Chain", "ASC") {

    // Define the admin (deployer)
    address public admin;

    // Define a modifier to restrict access to only the admin (deployer)
    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin");
        _;
    }

    struct AmmunitionToken {
        string batchID;
        uint256 quantity;
        string ammoType;
        string status; // e.g., "Manufactured", "In Transit", "Stocked", "Issued"
        address currentOwner;
    }

    // Mapping to store authorized manufacturers
    mapping(address => bool) public authorizedManufacturers;

    // Mapping to store all ammunition tokens by their batchID
    mapping(string => AmmunitionToken) public tokens;

    // Events to emit when state changes occur
    event TokenMinted(address indexed manufacturer, string batchID, uint256 quantity);
    event TokenTransferred(string batchID, address indexed newOwner);
    event TokenReceived(string batchID, address indexed depot);
    event TokenIssued(string batchID, address indexed armyUnit);

    // Constructor to initialize the contract and authorized manufacturers
    constructor(address[] memory initialManufacturers)  {
        admin = msg.sender; // The deployer becomes the admin
        for (uint256 i = 0; i < initialManufacturers.length; i++) {
            authorizedManufacturers[initialManufacturers[i]] = true;
        }
    }

    // Function to mint a new token for an ammunition batch
    function mintToken(
        string memory _batchID,
        uint256 _quantity,
        string memory _type
    ) public {
        require(bytes(_batchID).length > 0, "Batch ID required");
        require(_quantity > 0, "Quantity must be positive");

        // Create a new token representing the ammunition batch
        tokens[_batchID] = AmmunitionToken({
            batchID: _batchID,
            quantity: _quantity,
            ammoType: _type,
            status: "Manufactured",
            currentOwner: msg.sender
        });

        // Mint an ERC721 token with a unique token ID derived from the batch ID
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_batchID)));
        _mint(msg.sender, tokenId);

        emit TokenMinted(msg.sender, _batchID, _quantity);
    }

    // Function to transfer the token to the transport agency
    function transferToTransport(string memory _batchID, address _transportAgency) public {
        require(tokens[_batchID].currentOwner == msg.sender || msg.sender == admin, "You are neither the owner of this batch nor an admin.");
        require(keccak256(abi.encodePacked(tokens[_batchID].status)) == keccak256(abi.encodePacked("Manufactured")), "Invalid token status");

        tokens[_batchID].currentOwner = _transportAgency;
        tokens[_batchID].status = "In Transit";

        emit TokenTransferred(_batchID, _transportAgency);
    }

    // Function to receive the token at the depot
    function receiveAtDepot(string memory _batchID, address _depot) public onlyAdmin{
        require(tokens[_batchID].currentOwner == msg.sender || msg.sender == admin, "You are neither the owner of this batch nor an admin.");

        require(keccak256(abi.encodePacked(tokens[_batchID].status)) == keccak256(abi.encodePacked("In Transit")), "Batch not in transit");

        tokens[_batchID].currentOwner = _depot;
        tokens[_batchID].status = "Stocked";

        emit TokenReceived(_batchID, _depot);
    }

    // Function to issue the token to the army unit
    function issueToArmyUnit(string memory _batchID, address _armyUnit) public {
        require(tokens[_batchID].currentOwner == msg.sender || msg.sender == admin, "You are neither the owner of this batch nor an admin.");
        require(keccak256(abi.encodePacked(tokens[_batchID].status)) == keccak256(abi.encodePacked("Stocked")), "Batch not available in stock");

        tokens[_batchID].currentOwner = _armyUnit;
        tokens[_batchID].status = "Issued";

        emit TokenIssued(_batchID, _armyUnit);
    }

    // Function to add new manufacturers to the authorized list
    function addManufacturer(address _manufacturer) public onlyAdmin {
        authorizedManufacturers[_manufacturer] = true;
    }
}
