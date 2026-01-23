// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    OmniUtilCore v2
    World-class utility & reward infrastructure
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OmniUtilCoreV2 is ERC20, Ownable2Step, ReentrancyGuard {

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        CORE ROLES
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    address public immutable CREATOR;
    address public immutable TREASURY;
    address public AI_COORDINATOR;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        PARTNERS & ECOSYSTEMS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    enum PartnerLevel { NONE, BASIC, VERIFIED, CERTIFIED, ELITE }

    struct Partner {
        bool active;
        PartnerLevel level;
        uint256 rewardRate;      // % reward
        uint256 loyaltyFactor;   // % bonus
        address ecosystem;
        uint256 stakedUTIL;
    }

    mapping(address => Partner) public partners;
    mapping(address => address) public userEcosystem;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        INFLATION CONTROL
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    uint256 public immutable MAX_ANNUAL_MINT;
    uint256 public mintedThisYear;
    uint256 public lastInflationReset;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SECURITY & VALIDATION
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    mapping(bytes32 => bool) public validatedConsumptions;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        EVENTS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    event PartnerRegistered(address indexed partner);
    event PartnerUpdated(address indexed partner, PartnerLevel level);
    event RewardMinted(address indexed user, uint256 netAmount);
    event FeesDistributed(uint256 creatorFee, uint256 treasuryFee, uint256 burned);
    event ConsumptionValidated(bytes32 indexed hash);
    event EcosystemTransfer(address indexed from, address indexed to, uint256 amount);
    event FraudFlagged(address indexed user, string reason);

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MODIFIERS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    modifier onlyAI() {
        require(msg.sender == AI_COORDINATOR, "AI only");
        _;
    }

    modifier inflationGuard(uint256 amount) {
        if (block.timestamp > lastInflationReset + 365 days) {
            mintedThisYear = 0;
            lastInflationReset = block.timestamp;
        }
        require(mintedThisYear + amount <= MAX_ANNUAL_MINT, "Inflation cap");
        _;
        mintedThisYear += amount;
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        CONSTRUCTOR
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    constructor(
    address _creator,
    address _treasury,
    address _ai
)
    ERC20("OmniUtil", "UTIL")
    Ownable(_creator)
{
    CREATOR = _creator;
    TREASURY = _treasury;
    AI_COORDINATOR = _ai;

    MAX_ANNUAL_MINT = 10_000_000 * 10 ** decimals();
    lastInflationReset = block.timestamp;

    _mint(_creator, 1_000_000 * 10 ** decimals());
}
    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        PARTNER MANAGEMENT
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function registerPartner(
        address partner,
        uint256 rewardRate,
        uint256 loyaltyFactor,
        address ecosystem
    ) external onlyOwner {
        partners[partner] = Partner(
            true,
            PartnerLevel.BASIC,
            rewardRate,
            loyaltyFactor,
            ecosystem,
            0
        );
        emit PartnerRegistered(partner);
    }

    function updatePartner(
        address partner,
        PartnerLevel level,
        uint256 rewardRate,
        uint256 loyaltyFactor
    ) external onlyAI {
        require(partners[partner].active, "Not partner");
        partners[partner].level = level;
        partners[partner].rewardRate = rewardRate;
        partners[partner].loyaltyFactor = loyaltyFactor;
        emit PartnerUpdated(partner, level);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        CONSUMPTION VALIDATION
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function validateConsumption(bytes32 hash) external onlyAI {
        validatedConsumptions[hash] = true;
        emit ConsumptionValidated(hash);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        REWARD MINTING (CORE LOGIC)
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function mintReward(
        address user,
        address partner,
        uint256 usdAmount,
        bytes32 validationHash
    )
        external
        onlyAI
        nonReentrant
        inflationGuard(usdAmount * partners[partner].rewardRate / 100)
    {
        require(validatedConsumptions[validationHash], "Not validated");
        require(partners[partner].active, "Invalid partner");

        delete validatedConsumptions[validationHash];

        uint256 base = (usdAmount * partners[partner].rewardRate) / 100;
        uint256 loyalty = (base * partners[partner].loyaltyFactor) / 100;
        uint256 total = base + loyalty;

        uint256 creatorFee = total / 100;        // 1%
        uint256 treasuryFee = total / 100;       // 1%
        uint256 burnFee = total / 200;           // 0.5%

        uint256 net = total - creatorFee - treasuryFee - burnFee;

        _mint(user, net);
        _mint(CREATOR, creatorFee);
        _mint(TREASURY, treasuryFee);
        _burn(address(this), burnFee);

        emit RewardMinted(user, net);
        emit FeesDistributed(creatorFee, treasuryFee, burnFee);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ECOSYSTEM TRANSFERS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function transferInEcosystem(address to, uint256 amount) external {
        require(
            partners[userEcosystem[msg.sender]].ecosystem ==
            partners[userEcosystem[to]].ecosystem,
            "Different ecosystem"
        );
        _transfer(msg.sender, to, amount);
        emit EcosystemTransfer(msg.sender, to, amount);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        STABILITY TOOLS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function mintForStability(uint256 amount)
        external
        onlyOwner
        inflationGuard(amount)
    {
        _mint(TREASURY, amount);
    }

    function burnForStability(uint256 amount) external onlyOwner {
        _burn(TREASURY, amount);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ADMIN
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
    function setAICoordinator(address ai) external onlyOwner {
        AI_COORDINATOR = ai;
    }

    function flagFraud(address user, string calldata reason) external onlyOwner {
        emit FraudFlagged(user, reason);
    }
}
