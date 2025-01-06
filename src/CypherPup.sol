// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CypherPup is ERC20, ERC20Burnable, Ownable, Pausable {
    uint256 private constant TOTAL_SUPPLY = 50_000_000_000 * 10**18; // 50 billion tokens
    uint256 public constant MAX_WALLET_CAP = TOTAL_SUPPLY * 2 / 100; // 2% of total supply
    uint256 public constant TRANSACTION_LIMIT = TOTAL_SUPPLY * 5 / 1000; // 0.5% of total supply

    uint256 public redistributionFee = 1; // 1%
    uint256 public burnFee = 1; // 1%
    uint256 private constant FEE_DENOMINATOR = 100;

    address public liquidityWallet;
    mapping(address => bool) private excludedFromFees;

    constructor(address _liquidityWallet, address _multisigWallet) ERC20("CypherPup", "$CPHP") Ownable(msg.sender) Pausable() {
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero address");
        require(_multisigWallet != address(0), "Multisig wallet cannot be zero address");


        liquidityWallet = _liquidityWallet;
        excludedFromFees[msg.sender] = true;
        excludedFromFees[_liquidityWallet] = true;

        _mint(msg.sender, TOTAL_SUPPLY);

        // Transfer ownership to the multisig wallet
        transferOwnership(_multisigWallet);

        // Start contract in Paused state
        _pause();
    }

    modifier antiWhale(address from, address to, uint256 amount) {
        if (!excludedFromFees[to]) {
            require(balanceOf(to) + amount <= MAX_WALLET_CAP, "Exceeds max wallet cap");
        }
        if (!excludedFromFees[from]) {
            require(amount <= TRANSACTION_LIMIT, "Exceeds transaction limit");
        }
        _;
    }

    function setRedistributionFee(uint256 _redistributionFee) external onlyOwner {
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

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        excludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return excludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override antiWhale(from, to, amount) {
        uint256 transferAmount = amount;

        if (!excludedFromFees[from] && !excludedFromFees[to] && !paused()) {
            uint256 fees = (amount * (redistributionFee + burnFee)) / FEE_DENOMINATOR;
            uint256 burnAmount = (amount * burnFee) / FEE_DENOMINATOR;

            super._burn(from, burnAmount);
            transferAmount = amount - fees;

            // Redistribute fees
            _transfer(from, liquidityWallet, fees - burnAmount);
        }

        super._transfer(from, to, transferAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
