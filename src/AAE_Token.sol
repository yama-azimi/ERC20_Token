// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title AAE_Token: An ERC20 token that is Ownable, Pausable, and Burnable
/// @dev This contract implements an ERC20 token with extensions for pausability, burnability, and ownership transfer.
contract AAE_Token {
    string public constant name = "AAE_Token";
    string public constant symbol = "AAET";
    uint8 public constant decimals = 18;
    /// @notice Total supply of tokens, initially set to 1,000,000 tokens (including decimals)
    uint256 public totalSupply = 1000000 * 10 ** decimals;
    /// @notice Initial circulating supply set to 100,000 tokens (including decimals)
    uint256 public initialSupply = 100000 * 10 ** decimals;

    /// @notice Address of the contract owner
    address public owner;
    /// @notice Boolean flag indicating if the contract is paused
    bool public paused = false;

    /// @dev Mapping of account addresses to their balance
    mapping(address => uint256) balances;
    /// @dev Mapping of account addresses to another account's allowed withdrawal amount
    mapping(address => mapping(address => uint256)) allowed;

    /// @notice Emitted when tokens are transferred, including zero value transfers
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @notice Emitted when a successful approval of allowances is made
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    /// @notice Emitted when ownership of the contract is transferred
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /// @notice Emitted when the contract is paused
    event Paused();
    /// @notice Emitted when the contract is unpaused
    event Unpaused();
    /// @notice Emitted when tokens are burned
    event Burn(address indexed burner, uint256 value);

    /// @dev Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /// @dev Modifier to make functions callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @notice Contract constructor that sets the initial contract owner and allocates the initial supply to them
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = initialSupply;
    }

    /// @notice Transfers contract ownership to a new address
    /// @dev Requires the new owner to be a non-zero address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Pauses the contract, disabling functions marked with whenNotPaused
    /// @dev Can only be called by the contract owner
    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    /// @notice Unpauses the contract, enabling functions marked with whenNotPaused
    /// @dev Can only be called by the contract owner
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /// @notice Burns a specific amount of tokens from the caller's balance
    /// @dev Reduces the total supply of tokens
    /// @param amount The amount of tokens to be burned
    function burn(uint256 amount) public whenNotPaused {
        require(amount <= balances[msg.sender], "Insufficient balance");
        // Adjust this line to modify totalSupply instead of initialSupply
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
    }

    /// @notice Transfers a specific amount of tokens to a specified address
    /// @dev Requires the recipient address to be non-zero and the sender to have a sufficient balance
    /// @param to The recipient address
    /// @param amount The amount of tokens to transfer
    /// @return A boolean value indicating success
    function transfer(
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(to != address(0), "Transfer to the zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Returns the token balance of a specified address
    /// @param account The address to query the balance of
    /// @return The balance of the specified address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /// @notice Transfers tokens from one address to another
    /// @dev Requires the recipient address to be non-zero, the sender to have a sufficient balance and allowance for the transfer
    /// @param from The address to transfer tokens from
    /// @param to The address to transfer tokens to
    /// @param amount The amount of tokens to transfer
    /// @return A boolean value indicating success
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(to != address(0), "Transfer to the zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(
            allowed[from][msg.sender] >= amount,
            "Transfer amount exceeds allowance"
        );

        balances[from] -= amount;
        balances[to] += amount;
        allowed[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves an address to spend a specific amount of tokens on behalf of the caller
    /// @dev Emits an Approval event
    /// @param spender The address which will spend the funds
    /// @param amount The amount of tokens to be spent
    /// @return A boolean value indicating success
    function approve(
        address spender,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that an spender is allowed to spend on behalf of the owner
    /// @param _owner The address of the token owner
    /// @param _spender The address which will spend the tokens
    /// @return The number of tokens still available for the spender
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}
