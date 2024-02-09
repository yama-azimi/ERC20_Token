// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title AAE Token: An ERC20 Token with Ownership, Pausability, and Burnability Features
/// @dev Implements an ERC20 token standard with additional features: ownership management, pause functionality, and token burnability.
contract AAE_Token {
    /// @notice Token name for display
    string public constant name = "AAE_Token";
    /// @notice Token symbol for display
    string public constant symbol = "AAET";
    /// @notice Number of decimals for token
    uint8 public constant decimals = 18;
    /// @notice Total supply of tokens, initially set to 1,000,000 tokens (factoring in decimals)
    uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);
    /// @notice Circulating supply at contract deployment, set to 100,000 tokens (factoring in decimals)
    uint256 public initialSupply = 100000 * 10 ** uint256(decimals);

    /// @notice Address of the current owner
    address public owner;
    /// @notice Indicates if the contract's functionality is currently paused
    bool public paused = false;

    /// @dev Maps account addresses to their respective token balances
    mapping(address => uint256) private balances;
    /// @dev Maps owners to spenders with allowable withdrawal amounts
    mapping(address => mapping(address => uint256)) private allowed;

    /// @notice Emitted when tokens are transferred, including zero-value transfers
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @notice Emitted upon approval of a spender by an owner to spend tokens
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    /// @notice Emitted when ownership of the contract changes
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

    /// @dev Restricts function calls to the current owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /// @dev Ensures functions are callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @dev Sets the original `owner` of the contract to the sender account and allocates the initial supply to them
    constructor() {
        owner = msg.sender;
        balances[owner] = initialSupply;
    }

    /// @notice Allows for the transfer of contract ownership to a new address
    /// @param newOwner The address to become the new owner
    /// @dev Requires the new owner to be a non-zero address to avoid burning tokens
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Pauses all functions affected by the `whenNotPaused` modifier
    /// @dev Can only be executed by the current owner
    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    /// @notice Unpauses the contract, allowing normal operations to resume
    /// @dev Can only be executed by the current owner
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /// @notice Allows tokens to be burned, reducing the total supply
    /// @param amount The amount of tokens to burn from the caller's balance
    /// @dev Adjusts both the caller's balance and the total supply
    function burn(uint256 amount) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
    }

    /// @notice Transfers tokens to a specified address
    /// @param to The recipient's address
    /// @param amount The amount of tokens to transfer
    /// @dev Checks for non-zero recipient address and sufficient sender balance
    /// @return success A boolean value indicating whether the transfer was successful
    function transfer(
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool success) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Returns the balance of a specified address
    /// @param account The address to query the balance of
    /// @return balance The token balance of the queried address
    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }

    /// @notice Transfers tokens on behalf of an owner to a specified address
    /// @param from The owner's address
    /// @param to The recipient's address
    /// @param amount The amount of tokens to transfer
    /// @dev Checks for non-zero recipient address, sufficient balance, and allowance
    /// @return success A boolean value indicating whether the transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool success) {
        require(to != address(0), "Cannot transfer to the zero address");
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

    /// @notice Approves a spender to use a specified amount of the owner's tokens
    /// @param spender The address authorized to spend
    /// @param amount The amount of tokens they are authorized to use
    /// @dev Emits an Approval event signaling the update
    /// @return success A boolean value indicating whether the approval was successful
    function approve(
        address spender,
        uint256 amount
    ) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns the remaining amount of tokens that a spender is allowed to spend on behalf of an owner
    /// @param _owner The owner's address
    /// @param _spender The spender's address
    /// @return remaining The remaining allowance of tokens
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
