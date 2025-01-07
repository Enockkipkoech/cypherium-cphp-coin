// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CypherPup is ERC20, ERC20Burnable, Ownable, Pausable, AccessControl {
    // TOKENOMICS
    uint256 private constant TOTAL_SUPPLY = 50_000_000_000 * 10 ** 18; // 50 billion tokens
    uint256 public constant FEE_DENOMINATOR = 100;

    uint256 public redistributionFee = 1; // 1%
    uint256 public burnFee = 1; // 1%

    // OWNERSHIP
    address public liquidityWallet;
    address public multisigWallet;
    mapping(address => bool) private excludedFromFees;
    address public multisigOwner;

    // WHITELISTS
    mapping(address => uint8) public whitelist;

    // DISTRIBUTION WALLETS
    address public publicSaleWallet;
    address public communityRewardsWallet;
    address public liquidityPoolsWallet;
    address public developmentFundWallet;
    address public marketingPartnershipWallet;
    address public teamAdvisorsWallet;
    address public charitableFundWallet;

    // EVENTS
    event WhitelistUpdated(address account, uint8 category, bool status);
    event TokensDistributed(
        uint256 totalAmount,
        uint256 publicSaleAmount,
        uint256 communityRewardsAmount,
        uint256 liquidityPoolsAmount,
        uint256 developmentFundAmount,
        uint256 marketingPartnershipAmount,
        uint256 teamAdvisorsAmount,
        uint256 charitableFundAmount
    );

    // ROLES
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // MODIFIERS
    modifier verifyRole(bytes32 role) {
        require(
            hasRole(role, msg.sender),
            "Caller does not have the required role"
        );
        _;
    }

    constructor(
        address _multisigWallet,
        address _liquidityWallet,
        address _publicSale,
        address _communityRewards,
        address _liquidityPools,
        address _developmentFund,
        address _marketingPartnership,
        address _teamAdvisors,
        address _charitableFund
    )
        ERC20("CypherPup", "$CPHP")
        Ownable(msg.sender)
        Pausable()
        AccessControl()
    {
        liquidityWallet = _liquidityWallet;
        multisigWallet = _multisigWallet;
        publicSaleWallet = _publicSale;
        communityRewardsWallet = _communityRewards;
        liquidityPoolsWallet = _liquidityPools;
        developmentFundWallet = _developmentFund;
        marketingPartnershipWallet = _marketingPartnership;
        teamAdvisorsWallet = _teamAdvisors;
        charitableFundWallet = _charitableFund;

        require(
            liquidityWallet != address(0) &&
                multisigWallet != address(0) &&
                publicSaleWallet != address(0) &&
                communityRewardsWallet != address(0) &&
                liquidityPoolsWallet != address(0) &&
                developmentFundWallet != address(0) &&
                marketingPartnershipWallet != address(0) &&
                teamAdvisorsWallet != address(0) &&
                charitableFundWallet != address(0),
            "One or more wallet addresses are invalid"
        );

        excludedFromFees[msg.sender] = true;
        excludedFromFees[_liquidityWallet] = true;

        // Mint initial supply
        _mint(msg.sender, TOTAL_SUPPLY);

        // Transfer ownership to the multisig wallet
        transferOwnership(_multisigWallet);
        multisigOwner = _multisigWallet;

        // Grant roles
        AccessControl._grantRole(DEFAULT_ADMIN_ROLE, multisigOwner);
        AccessControl._grantRole(MINTER_ROLE, _multisigWallet);
        AccessControl._grantRole(ADMIN_ROLE, _multisigWallet);
    }

    function mintAndDistribute(uint256 amount) external onlyRole(MINTER_ROLE) {
        require(amount > 0, "Mint amount must be greater than 0");

        // Mint tokens to the contract first
        _mint(address(this), amount);

        // Ensure contract has enough tokens for distribution
        require(
            balanceOf(address(this)) >= amount,
            "Insufficient contract balance for distribution"
        );

        // Calculate distribution amounts
        uint256 publicSaleAmount = (amount * 40) / 100;
        uint256 communityRewardsAmount = (amount * 20) / 100;
        uint256 liquidityPoolsAmount = (amount * 15) / 100;
        uint256 developmentFundAmount = (amount * 10) / 100;
        uint256 marketingPartnershipAmount = (amount * 7) / 100;
        uint256 teamAdvisorsAmount = (amount * 5) / 100;
        uint256 charitableFundAmount = (amount * 3) / 100;

        // Transfer tokens to respective wallets
        _transfer(address(this), publicSaleWallet, publicSaleAmount);
        _transfer(
            address(this),
            communityRewardsWallet,
            communityRewardsAmount
        );
        _transfer(address(this), liquidityPoolsWallet, liquidityPoolsAmount);
        _transfer(address(this), developmentFundWallet, developmentFundAmount);
        _transfer(
            address(this),
            marketingPartnershipWallet,
            marketingPartnershipAmount
        );
        _transfer(address(this), teamAdvisorsWallet, teamAdvisorsAmount);
        _transfer(address(this), charitableFundWallet, charitableFundAmount);

        emit TokensDistributed(
            amount,
            publicSaleAmount,
            communityRewardsAmount,
            liquidityPoolsAmount,
            developmentFundAmount,
            marketingPartnershipAmount,
            teamAdvisorsAmount,
            charitableFundAmount
        );
    }

    // Whitelist management functions
    function addToWhitelist(
        address account,
        uint8 category
    ) external verifyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        whitelist[account] = category;
        emit WhitelistUpdated(account, category, true);
    }

    function removeFromWhitelist(
        address account
    ) external verifyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        delete whitelist[account];
        emit WhitelistUpdated(account, 0, false); // 0 as no category
    }

    // SECURITY FUNCTIONS
    modifier antiWhale(
        address from,
        address to,
        uint256 amount
    ) {
        if (!excludedFromFees[to]) {
            require(
                balanceOf(to) + amount <= getMaxWalletCap(),
                "Exceeds max wallet cap"
            );
        }
        if (!excludedFromFees[from]) {
            require(
                amount <= getTransactionLimit(),
                "Exceeds transaction limit"
            );
        }
        _;
    }

    function setRedistributionFee(
        uint256 _redistributionFee
    ) external onlyOwner {
        require(_redistributionFee <= 10, "Fee cannot exceed 10%");
        redistributionFee = _redistributionFee;
    }

    function setBurnFee(uint256 _burnFee) external onlyOwner {
        require(_burnFee <= 10, "Fee cannot exceed 10%");
        burnFee = _burnFee;
    }

    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        require(_liquidityWallet != address(0), "Invalid address");
        liquidityWallet = _liquidityWallet;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        excludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return excludedFromFees[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public override antiWhale(msg.sender, to, amount) returns (bool) {
        uint256 transferAmount = amount;

        if (
            !excludedFromFees[msg.sender] && !excludedFromFees[to] && !paused()
        ) {
            uint256 fees = (amount * (redistributionFee + burnFee)) /
                FEE_DENOMINATOR;
            uint256 burnAmount = (amount * burnFee) / FEE_DENOMINATOR;

            _burn(msg.sender, burnAmount);
            transferAmount = amount - fees;

            // Redistribute fees
            _transfer(msg.sender, liquidityWallet, fees - burnAmount);
        }

        _transfer(msg.sender, to, transferAmount);
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getMaxWalletCap() public view returns (uint256) {
        return (totalSupply() * 2) / 100; // 2% of total supply
    }

    function getTransactionLimit() public view returns (uint256) {
        return (totalSupply() * 5) / 1000; // 0.5% of total supply
    }
}
