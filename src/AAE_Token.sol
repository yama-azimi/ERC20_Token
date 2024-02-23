// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title AAE Token: An ERC20 Token with Ownership, Pausability, and Burnability Features
 * @dev Implements an ERC20 token standard with additional features: ownership management, pause functionality, and token burnability.
 */
contract AAE_Token {
    string public constant NAME = "AAE_Token";
    string public constant SYMBOL = "AAET";
    uint8 public constant DECIMALS = 18;
    uint256 public totalSupply;

    address public owner;
    bool public paused;

    mapping(address => uint256) private balances; // @dev Tracks the balance of each address.
    mapping(address => mapping(address => uint256)) private allowed; // @dev Tracks the allowance granted from one address to another.

    /**
     * @dev Emitted when tokens are transferred, including zero-value transfers.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted upon approval of a spender by an owner to spend tokens.
     * @param owner The address approving the spending.
     * @param spender The address approved to spend.
     * @param value The amount of tokens approved.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when ownership of the contract changes.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when the contract is paused.
     */
    event Paused();

    /**
     * @dev Emitted when the contract is unpaused.
     */
    event Unpaused();

    /**
     * @dev Emitted when tokens are burned.
     * @param burner The address that burned the tokens.
     * @param value The amount of tokens burned.
     */
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /**
     * @dev Initializes the contract, setting the deployer as the initial owner and allocating the initial total supply to them.
     */
    constructor() {
        owner = msg.sender;
        totalSupply = 1000000 * 10 ** uint256(DECIMALS);
        balances[owner] = totalSupply;
    }

    /**
     * @dev Burns a specific amount of tokens from the caller’s account, reducing the total supply.
     * @param amount The amount of tokens to be burned.
     * @return A boolean value indicating whether the operation was successful.
     */
    function burn(uint256 amount) external whenNotPaused returns (bool) {
        require(amount > 0, "Burn amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");

        // Update state variables in a safe manner
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        // Emit an event to log the burn action
        emit Burn(msg.sender, amount);

        return true;
    }

    /**
     * @dev Transfers a specific amount of tokens to a specified address.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return success A boolean indicating success of the transfer.
     */
    function transfer(
        address to,
        uint256 amount
    ) external whenNotPaused returns (bool success) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another, provided the transaction is approved.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount of tokens to transfer.
     * @return success A boolean indicating success of the transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external whenNotPaused returns (bool success) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(
            allowed[from][msg.sender] >= amount,
            "Transfer amount exceeds allowance"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        balances[from] -= amount;
        balances[to] += amount;
        allowed[from][msg.sender] -= amount;
        emit Transfer(from, to, amount); // Correctly emitting Transfer event
        return true;
    }

    /**
     * @dev Approves a spender to transfer a specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     * @return success A boolean indicating the success of the operation.
     */
    function approve(
        address spender,
        uint256 amount
    ) external whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfers contract ownership to a new address.
     * @param newOwner The address to be set as the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Pauses the contract, preventing execution of functions marked with whenNotPaused.
     */
    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of functions marked with whenNotPaused.
     */
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /**
     * @dev Increases the allowance granted to a spender.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     * @return A boolean indicating if the operation was successful.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decreases the allowance granted to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     * @return A boolean indicating if the operation was successful.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        uint256 currentAllowance = allowed[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            allowed[msg.sender][spender] = currentAllowance - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Returns the balance of a specified address.
     * @param account The address to query the balance of.
     * @return The number of tokens belonging to the specified address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Returns the amount of tokens that an owner has allowed a spender to use.
     * @param _owner The address of the owner.
     * @param _spender The address of the spender.
     * @return remaining The remaining amount of tokens that the spender is allowed to spend.
     */
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
